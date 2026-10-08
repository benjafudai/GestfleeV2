class PartQuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_part

  def create
    @part_quote = @part.part_quotes.build(part_quote_params.merge(user: current_user, company: @part.company))
    authorize @part_quote

    if @part_quote.save
      redirect_to @part, notice: "Cotización registrada."
    else
      redirect_to @part, alert: "No se pudo registrar la cotización: #{@part_quote.errors.full_messages.to_sentence}."
    end
  end

  def destroy
    part_quote = @part.part_quotes.find(params[:id])
    authorize part_quote
    part_quote.destroy
    redirect_to @part, notice: "Cotización eliminada."
  end

  private

  def set_part
    @part = Part.find(params[:part_id])
  end

  def part_quote_params
    params.require(:part_quote).permit(:supplier, :price, :currency, :quoted_on, :url, :notes)
  end
end
