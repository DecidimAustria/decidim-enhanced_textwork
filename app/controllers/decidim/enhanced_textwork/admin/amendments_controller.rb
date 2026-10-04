# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class AmendmentsController < ApplicationController
        def decide
          amendment = Amendment.where(component: current_component).find(params[:id])
          DecideAmendment.call(amendment, current_user, params[:state], params[:decision_reason])
          redirect_to Decidim::EngineRouter.main_proxy(current_component).amendment_path(amendment)
        rescue DecideAmendment::Conflict
          render plain: I18n.t("decidim.enhanced_textwork.texts.conflict"), status: :conflict
        rescue ArgumentError
          head :unprocessable_content
        end
      end
    end
  end
end
