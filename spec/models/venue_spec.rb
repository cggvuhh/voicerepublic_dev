require 'rails_helper'

uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

RSpec.describe Venue, type: :model do

  describe 'validates' do
    it 'presence of name' do
      talk = FactoryGirl.build(:venue)
      talk.name = nil
      expect(talk).to be_invalid
    end

    it 'presence of user' do
      talk = FactoryGirl.build(:venue)
      talk.user = nil
      expect(talk).to be_invalid
    end
  end

  describe 'friendly id' do
    it 'has a slug' do
      talk = FactoryGirl.create(:venue)
      expect(talk.slug).to be_present
    end

    it 'uses the id and name if name is taken' do
      talk0 = FactoryGirl.create(:venue, name: 'hello')
      expect(talk0.slug).to eq('hello')
      talk1 = FactoryGirl.create(:venue, name: 'hello')
      expect(talk1.slug).to match(/\Ahello-[a-f\d\-]+\z/)
    end
  end

  describe 'options' do
    it 'deserialized' do
      talk = FactoryGirl.build(:venue)
      expect(talk.options).to be_a(Hash)
    end

    it 'provide a handy shortcut' do
      talk = FactoryGirl.build(:venue, options: { bla: 'blub' } )
      expect(talk.opts.bla).to eq('blub')
    end
  end

  describe 'storage related' do
    it 'provides a method to infer relevant files' do
      talk = FactoryGirl.build(:venue)
      names = [
        "dump_#{2.days.ago.to_i}",
        "dump_#{2.hours.ago.to_i}",
        "dump_#{61.minutes.ago.to_i}",
        "dump_#{60.minutes.ago.to_i}",
        "dump_#{59.minutes.ago.to_i}",
        "dump_#{1.minute.ago.to_i}"
      ]
      started_at = 60.minutes.ago.to_i
      ended_at = 30.minutes.ago.to_i
      result = talk.relevant_files(started_at, ended_at, names)
      expect(result.map(&:first).sort).to eq(names[2,3])
    end
  end

  describe 'streaming related' do
    describe 'built' do
      before do
        @venue = FactoryGirl.build(:venue)
      end

      it 'generates client tokens' do
        @venue.slug = 'hello'
        token = @venue.generate_client_token
        # slug - timestamp (10 digits) - password (4 chars)
        expect(token).to match(/\A.*-\d{10}-\w{4}\z/)
      end

      it 'generates mount points' do
        mount_point = @venue.generate_mount_point
        expect(mount_point).to eq('live')#match(uuid_regex)
      end

      it 'generates passwords' do
        password = @venue.generate_password
        expect(password).to match(/\A\w{8}\z/) # by default 8
        password = @venue.generate_password(4)
        expect(password).to match(/\A\w{4}\z/)
      end

      it 'provides provisioning parameters' do
        @venue.client_token = 'some-client-token'
        params = @venue.provisioning_parameters
        expect(params).to be_an(Array)
        expect(params.length).to eq(4)
        expect(params[0]).to eq(Settings.icecast.ec2.image)
        expect(params[1]).to eq(1)
        expect(params[2]).to eq(1)
        options = params[3]
        expect(options['InstanceType']).to eq(@venue.instance_type)
        expect(options['ClientToken']).to eq(@venue.client_token)
        expect(options['KeyName']).to be_present
        expect(options['SecurityGroup']).to be_present
        expect(options['UserData']).to be_present
      end

      it 'provides userdata' do
        userdata = @venue.userdata
        expect(userdata).to include(@venue.icecast_callback_url)
      end

      it 'provides icecast callback urls' do
        url = @venue.icecast_callback_url
        expect(url).to match(%r{\Ahttps?://})
      end
    end

    describe 'created' do
      before do
        @venue = FactoryGirl.create(:venue)
      end

      it 'has the default_instance_type set' do
        default = Settings.icecast.ec2.default_instance_type
        expect(@venue.instance_type).to eq(default)
      end

      it 'starts provisioning'

      it 'completes provisioning'

      it "knows if it's safe to shut down"

      it 'unprovisions'
    end

    describe 'created and awaiting_stream' do
      before do
        @venue = FactoryGirl.create(:venue, :awaiting_stream)
      end

      it 'compiles stream urls' do
        url = @venue.build_stream_url
        expect(url).to include(@venue.public_ip_address)
        expect(url).to include(@venue.mount_point)
      end

      it 'provides darkice configs' do
        config = @venue.darkice_config
        expect(config).to include(@venue.mount_point)
        expect(config).to include(@venue.public_ip_address)
        expect(config).to include(@venue.source_password)
        expect(config).to include(@venue.port.to_s)
      end
    end
  end

  describe 'scopes' do
    it 'provides not_offline' do
      expected = [
        FactoryGirl.create(:venue, :available),
        FactoryGirl.create(:venue, :provisioning),
        FactoryGirl.create(:venue, :device_required),
        FactoryGirl.create(:venue, :awaiting_stream),
        FactoryGirl.create(:venue, :connected),
        FactoryGirl.create(:venue, :disconnect_required),
        FactoryGirl.create(:venue, :disconnected)
      ]
      unexpected = [
        FactoryGirl.create(:venue)
      ]
      venues = Venue.not_offline
      expected.each do |expectation|
        expect(venues).to include(expectation)
      end
      unexpected.each do |suprise|
        expect(venues).not_to include(suprise)
      end
    end

    it 'provides with_live_talks' do
      venue = FactoryGirl.create(:venue)
      FactoryGirl.create(:talk, :live, venue: venue)
      unexpected = FactoryGirl.create(:venue)

      venues = Venue.with_live_talks
      expect(venues).to include(venue)
      expect(venues).not_to include(unexpected)
    end

    it 'provides with_upcoming_talks' do
      venue = FactoryGirl.create(:venue)
      FactoryGirl.create(:talk, :prelive, venue: venue)
      unexpected = FactoryGirl.create(:venue)

      venues = Venue.with_upcoming_talks
      expect(venues).to include(venue)
      expect(venues).not_to include(unexpected)
    end

  end

end
