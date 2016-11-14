class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds CurationConcerns behaviors to the application controller.
  include CurationConcerns::ApplicationControllerBehavior
  # Adds Sufia behaviors into the application controller
  include Sufia::Controller

  include ApplicationHelper

  include CurationConcerns::ThemedLayoutController
  layout 'sufia-one-column'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do
    if user_signed_in?
      redirect_to main_app.root_path, alert: 'You are not authorized to view this resource.'
    else
      redirect_to omniauth_authorize_path(:user, login_strategy)
    end
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  protected

  def disable_turbolinks
    @disable_turbolinks = true
  end
end
