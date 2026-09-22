class ChecklistSubmissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_submission, only: %i[show review]

  def index
    authorize ChecklistSubmission
    @submissions = policy_scope(ChecklistSubmission).recent
                                                    .includes(:checklist_template, :vehicle, :user)
  end

  def show
    authorize @submission
    @answers = @submission.checklist_answers.includes(:checklist_item)
  end

  def new
    authorize ChecklistSubmission
    
    if current_user.checklist_submissions.where(submitted_at: Time.current.all_day).exists?
      redirect_to checklist_submissions_path, alert: "Ya has completado tu checklist del día de hoy."
      return
    end

    @templates = ChecklistTemplate.all.order(:name)
    # El chofer sólo puede hacer checklist del vehículo que tiene asignado
    @assignment = current_user.vehicle_assignments.find_by(ended_on: nil)
    @vehicle    = @assignment&.vehicle

    @submission = ChecklistSubmission.new(
      user: current_user,
      vehicle: @vehicle
    )
    @selected_template = @templates.first
  end

  def create
    authorize ChecklistSubmission
    @submission = ChecklistSubmission.new(submission_params)
    @submission.user = current_user

    if @submission.save
      redirect_to @submission, notice: "Checklist enviado correctamente."
    else
      puts "=== SUBMISSION ERRORS ==="
      puts @submission.errors.full_messages
      puts "========================="
      @templates = ChecklistTemplate.all.order(:name)
      @assignment = current_user.vehicle_assignments.find_by(ended_on: nil)
      @vehicle    = @assignment&.vehicle
      render :new, status: :unprocessable_entity
    end
  end

  def review
    authorize @submission
    if @submission.update(review_params)
      redirect_to @submission, notice: "Checklist revisado. Estado: #{@submission.status.humanize}."
    else
      redirect_to @submission, alert: "Error al revisar el checklist."
    end
  end

  private

  def set_submission
    @submission = ChecklistSubmission.find(params[:id])
  end

  def submission_params
    params.require(:checklist_submission).permit(
      :checklist_template_id,
      :vehicle_id,
      checklist_answers_attributes: %i[checklist_item_id value],
      photos: []
    )
  end

  def review_params
    params.require(:checklist_submission).permit(:status, :admin_notes)
  end
end
