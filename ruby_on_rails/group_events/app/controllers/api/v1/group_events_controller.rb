class Api::V1::GroupEventsController < Api::V1::Base
  SERIALIZER = Api::V1::GroupEventSerializer

  def count
    render json: { count: GroupEvent.active.count }, status: :ok
  end

  def index
    @group_events = GroupEvent.active

    if params[:limit].present?
      @group_events = @group_events.limit(params[:limit]&.to_i)
    end

    if params[:offset].present?
      @group_events = @group_events.offset(params[:offset]&.to_i)
    end

    render json: @group_events, each_serializer: SERIALIZER, status: :ok
  end

  def show
    @group_event = fetch_group_event(params[:id]) or return

    render json: @group_event, serializer: SERIALIZER, status: :ok
  end

  def create
    @group_event = GroupEvent.new(create_params)

    duration_in_days = params[:group_event][:duration_in_days].to_i rescue 0
    @group_event.duration = duration_in_days.days

    if @group_event.save
      return render json: @group_event, serializer: SERIALIZER, status: :ok
    end

    render json: {
      message: "Group event could not be created",
      errors: @group_event.errors.full_messages.as_json,
    }, status: :unprocessable_entity
  end

  def update
    @group_event = fetch_group_event(params[:id]) or return
    @group_event.assign_attributes(update_group_event_params)

    duration_in_days = params[:group_event][:duration_in_days].to_i rescue 0
    @group_event.duration = duration_in_days.days

    if @group_event.save
      return render json: @group_event, serializer: SERIALIZER, status: :ok
    end

    render json: {
      message: "Group event could not be updated",
      errors: @group_event.errors.full_messages.as_json,
    }, status: :unprocessable_entity
  end

  def destroy
    # Mark as deleted
    @group_event = fetch_group_event(params[:id]) or return

    if @group_event.soft_destroy
      return render json: { message: "Group event is deleted" }, status: :ok
    end

    render json: {
      message: "Group event could not be deleted",
      errors: @group_event.errors.full_messages.as_json,
    }, status: :unprocessable_entity
  end

  def restore
    # Restore deleted record
    @group_event = fetch_group_event(params[:id], true) or return

    if @group_event.soft_destroy
      return render json: { message: "Group event is restored" }, status: :ok
    end

    render json: {
      message: "Group event could not be restored",
      errors: @group_event.errors.full_messages.as_json,
    }, status: :unprocessable_entity
  end

  def publish
    @group_event = fetch_group_event(params[:id]) or return

    if @group_event.update(status: "published")
      return render json: { message: "Group event is published" }, status: :ok
    end

    render json: {
      message: "Group event could not be published",
      errors: @group_event.errors.full_messages.as_json,
    }, status: :unprocessable_entity
  end

  private

  def fetch_group_event(uuid, restore = false)
    events          = restore ? GroupEvent.soft_deleted : GroupEvent.all
    group_event     = events.where("uuid = ?", uuid).first
    failure_message = "This group event does not seem to exist anymore"

    return fetch_record_or_return_false(group_event, failure_message)
  end

  def create_params
    params.require(:group_event).
      permit(:uuid, :name, :description, :start_date, :end_date, :created_by_id, :location_id)
  end

  def update_group_event_params
    params.require(:group_event).
      permit(:name, :description, :start_date, :end_date, :created_by_id, :location_id)
  end
end
