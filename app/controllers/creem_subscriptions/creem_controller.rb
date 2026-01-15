# frozen_string_literal: true

module CreemSubscriptions
  class CreemController < ::ApplicationController
    requires_plugin CreemSubscriptions::PLUGIN_NAME
    
    skip_before_action :check_xhr
    skip_before_action :redirect_to_login_if_required

    def index
      render_json_dump({})
    end
  end
end
