class Users::SessionsController < Devise::SessionsController
  respond_to :json

  skip_before_action :verify_authenticity_token, if: lambda { request.format.json? }

  include Devise::Controllers::Rememberable

  # POST /resource/sign_in
  def create
    respond_with resource do |format|
      format.html do
        self.resource = warden.authenticate!(auth_options)
        set_flash_message(:notice, :signed_in) if is_navigational_format?

        sign_in(resource_name, resource)
        if params[:remember_me]
          remember_me(resource)
        end
        redirect_to after_sign_in_path_for(resource)
      end

      format.json do
        resource = resource_from_credentials

        #build_resource
        return invalid_login_attempt unless resource

        if resource.valid_password?(params[:password]) and resource.is_a? User
          user_hash = resource.attributes
          resource.venues.reload
          series = resource.venues.collect { |v| [v.id, v.title ]}
          user_hash.merge!(series: Hash[series])
          render json: user_hash.to_json
        else
          invalid_login_attempt
        end
      end
    end
  end

  # DELETE /resource/sign_out
  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to redirect_path }
    end
  end

  protected
  def invalid_login_attempt
    warden.custom_failure!
    render json: { success: false, errors: 'Error with your login or password' }, status: 401
  end

  def resource_from_credentials
    data = { email: params[:email] }
    if res = resource_class.find_for_database_authentication(data)
      return res if res.valid_password?(params[:password])
    end
  end

end
