require 'rails_helper'

RSpec.describe IiifGatekeeperController, type: :controller do
  describe 'actions' do
    it { is_expected.not_to use_before_action(:store_current_location) }
  end
end
