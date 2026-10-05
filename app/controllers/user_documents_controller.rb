class UserDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_user_document, only: %i[ edit update destroy ]

  def new
    @user_document = @user.user_documents.new
    authorize @user_document
  end

  def edit
    authorize @user_document
  end

  def create
    @user_document = @user.user_documents.new(user_document_params)
    @user_document.status = 'ok'
    authorize @user_document

    if @user_document.save
      redirect_to user_path(@user), notice: "Documento agregado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @user_document
    if @user_document.update(user_document_params)
      redirect_to user_path(@user), notice: "Documento actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user_document
    @user_document.destroy
    redirect_to user_path(@user), notice: "Documento eliminado."
  end

  private

  def set_user
    @user = current_user.company.users.find(params[:user_id]) if current_user.company
    @user ||= User.find(params[:user_id]) # fallback if superadmin
  end

  def set_user_document
    @user_document = @user.user_documents.find(params[:id])
  end

  def user_document_params
    params.require(:user_document).permit(:doc_type, :due_on, :notes, :file)
  end
end
