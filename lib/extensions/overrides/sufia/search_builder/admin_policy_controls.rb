module Overrides
  module Sufia
    module SearchBuilder
      module AdminPolicyControls
        extend ActiveSupport::Concern

        include ::Hydra::PolicyAwareAccessControlsEnforcement

        included do
          def logger
            Rails.logger
          end
        end
      end
    end
  end
end
