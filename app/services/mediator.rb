require File.expand_path(File.join(%w(.. .. .. lib services)), __FILE__)

require File.expand_path(File.join(%w(.. mediator dj_callback)), __FILE__)

# The Mediator's responsibility is to subscribe to relevant channels
# and transform events into human readable notifications and forward
# those to a notification channel.
#
# Messages in the `notifications` channel will be picked up an
# forwarded to some communication channel like Slack, IRC or Text
# Messages. Best practice is to use different channels for regocnized
# and yet unrecognized (generic/unformatted) messages.
#
class Mediator

  include Services::Subscriber  # provides `subscribe`
  include Services::Publisher   # provides `publish`
  include Services::LocalConfig # provides `config`
  include Services::AutoPublish # publishes the return value of handlers

  subscribe x: 'dj_callback', handler: DjCallback
  subscribe x: 'talk_transition'
  subscribe x: 'lifecycle_user'
  subscribe x: 'lifecycle_message'

  subscribe x: 'transaction_transition'

  def talk_transition(*args)
    body = args.shift
    event = body['details']['event'] * '.'
    intros = {
      'created.prelive.prepare'      => 'Has been created',
      'prelive.live.start_talk'      => 'Now live',
      'live.postlive.end_talk'       => 'Has come to end',
      'postlive.processing.process'  => 'Started processing',
      'processing.archived.archive'  => 'Just archived recording',
      'pending.archived.archive'     => 'Just archived upload',
      'processing.suspended.suspend' => 'Failed to process'
    }
    intro = intros[event]
    intro ||= 'Don\'t know how to format talk event `%s` for' % event
    talk = body['details']['talk']
    user = body['details']['user']
    _talk = slack_link(talk['title'], talk['url'])
    _user = slack_link(user['name'], user['url'])

    { x: 'notification', text: "#{intro} (#{talk['id']}) #{_talk} by #{_user}" }
  end


  # NOTE trouble to refactor this into a submodule, since it needs
  # access to `config` and `publish`
  def transaction_transition(*args)
    body = args.shift
    details = body['details']
    event = details['event']
    type = details['type']

    message =
      case event
      when %w(processing closed close)
        case type
        when 'PurchaseTransaction'
          # TODO
          user = 'Someone'
          product = 'something'
          price = 'some amount'
          publish x: 'notification',
                  channel: config.slack.revenue_channel,
                  text: '%s purchased %s for %s.' %
                  [user, product, price]
          return # abort early

        when 'ManualTransaction'
          admin    = details['admin']
          quantity = details['quantity'].to_i
          payment  = details['payment'].to_i
          name     = details['username']
          comment  = details['comment']

          movement = :unknown
          movement = :deduct if quantity < 0  and payment == 0
          movement = :undo   if quantity < 0  and payment < 0
          movement = :donate if quantity > 0  and payment == 0
          movement = :sale   if quantity > 0  and payment > 0
          movement = :track  if quantity == 0 and payment > 0
          movement = :noop   if quantity == 0 and payment == 0
          movement = :weird  if quantity < 0  and payment > 0
          movement = :weird  if quantity >= 0 and payment < 0

          case movement
          when :deduct
            'Admin %s deducted %s credits from %s with comment: %s' %
              [ admin, quantity, name, comment ]
          when :undo
            'Admin %s undid a booking for %s, by deducting %s credits ' +
              'and giving EUR %s back with comment: %s' %
              [ admin, name, quantity, payment, comment ]
          when :donate
            'Admin %s donated %s credits to %s with comment: %s' %
              [ admin, quantity, name, comment ]
          when :sale
            'Admin %s sold %s credits for EUR %s to %s with comment: %s' %
              [ admin, quantity, payment, name, comment ]
          when :track
            'Admin %s tracked a sale of EUR %s to %s, ' +
              'restrospectively with comment: %s' %
              [ admin, payment, name, comment ]
          when :noop
            'Admin %s contemplated about the meaning of life with comment: %s' %
              [ admin, comment ]
          when :weird
            'Admin %s and %s seem to be in cahoots. Alert the authorities, ' +
              'fishy transaction going on with comment: %s' %
              [ admin, name, comment ]
          else
            "Unknown movement #{movement}"
          end
        else
          "Unknown type #{type}"
        end
      else
        "Unknown transition #{event}"
      end

    # in lots of cases message is still nil, if so we don't send a message
    message.nil? ? nil : { x: 'notification', text: message }
  end


  def lifecycle_user(*args)
    body = args.shift
    name = body['details']['user']['name']
    email = body['details']['user']['email']
    message = "%s just registered with %s." % [name, email]

    { x: 'notification', text: message }
  end

  def lifecycle_message(*args)
    body = args.shift
    message = "Someone has posted a message. (#{body.inspect})"

    { x: 'notification', text: message }
  end


  def run
    publish x: 'notification', text: 'Mediator started.'
    super
  end

  private

  def slack_link(title, url)
    "<#{url}|#{title}>"
  end

end

# SERVICE Mediator
# dj_callback ->
# talk_transition ->
# lifecycle_user ->
# lifecycle_message ->
# transaction_transition ->
# -> notification
# -> techne