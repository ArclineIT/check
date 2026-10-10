class ChecksController < ApplicationController
  WATCH_RANGE = 10..3600

  rate_limit to: 30, within: 1.minute, only: :show, with: -> { render plain: "Too many checks. Try again in a minute.\n", status: :too_many_requests }

  def new
  end

  # GET /check?domain=example.com, also as .json and .txt.
  def show
    @domain = DomainName.parse(params[:domain])
    @report = TransparencyCheck.call(@domain)
    @watch = params[:watch].to_i.clamp(WATCH_RANGE) if params[:watch].present?

    respond_to do |format|
      format.html
      format.json { render json: @report }
      format.text { render plain: @report.to_text }
    end
  rescue DomainName::Invalid => e
    respond_to do |format|
      format.html { redirect_to root_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.text { render plain: "#{e.message}\n", status: :unprocessable_entity }
    end
  end
end
