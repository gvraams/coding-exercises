class Api::V1::GroupEventSerializer < ActiveModel::Serializer
  attributes(
    :uuid,
    :name,
    :description,
    :status,
    :created_by_id,
    :location_id,
    :start_date,
    :end_date,
    :duration
  )
end
