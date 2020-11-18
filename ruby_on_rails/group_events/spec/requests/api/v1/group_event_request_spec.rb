require 'rails_helper'

def validate_event_from_response(json_response, attributes)
  attributes = HashWithIndifferentAccess.new attributes
  json_response  = HashWithIndifferentAccess.new json_response

  lhs = json_response.slice(
    :created_by_id, :location_id, :name, :description, :duration, :status, :uuid)

  rhs = attributes.slice(
    :created_by_id, :location_id, :name, :description, :duration, :status, :uuid)

  lhs_start_date = DateTime.parse(json_response["start_date"]).change(:usec => 0)
  rhs_start_date = DateTime.parse(attributes["start_date"].to_s).change(:usec => 0)
  lhs_end_date   = DateTime.parse(json_response["end_date"]).change(:usec => 0)
  rhs_end_date   = DateTime.parse(attributes["end_date"].to_s).change(:usec => 0)

  # Validates json response
  expect(lhs).to eq(rhs)
  expect(lhs_start_date).to eq(rhs_start_date)
  expect(lhs_end_date).to eq(rhs_end_date)
end

RSpec.describe "Api::V1::GroupEvents", type: :request do
  let(:headers) {
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
    }
  }

  context "count" do
    it "active group events count" do
      group_event = create(:group_event)
      get('/api/v1/group_events/count', headers: headers)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({ "count" => 1 })
    end

    it "exclude records marked for deletion" do
      group_event = create(:group_event)
      group_event.soft_destroy

      get('/api/v1/group_events/count', headers: headers)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({ "count" => 0 })
    end
  end

  context "index" do
    it "HTTP response & status" do
      group_event = create(:group_event)
      attributes  = group_event.attributes
      get('/api/v1/group_events', headers: headers)

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      validate_event_from_response(json_response.first, group_event.attributes)
    end

    it "limit, offset & default order (:created_at => :asc)" do
      first = create(:group_event)

      second = create(:group_event, {
        created_by: first.created_by,
        location: first.location,
      })

      third = create(:group_event, {
        created_by: first.created_by,
        location: first.location,
      })

      # --- GET#index without :limit
      get('/api/v1/group_events', headers: headers)

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(3)

      # --- GET#index with :limit
      get('/api/v1/group_events', headers: headers, params: { limit: 1 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(first.uuid)

      # --- GET#index with :offset
      get('/api/v1/group_events', headers: headers, params: { offset: 2 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(third.uuid)

      # --- GET#index with both :limit & :offset
      get('/api/v1/group_events', headers: headers, params: { limit: 1, offset: 1 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(second.uuid)
    end
  end

  context "show" do
    it "HTTP response & status" do
      group_event = create(:group_event)
      attributes  = group_event.attributes
      get("/api/v1/group_events/#{group_event.uuid}", headers: headers)

      # Validates response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      validate_event_from_response(json_response, group_event.attributes)
    end
  end

  context "create" do
    it "create group event with valid attributes" do
      uuid        = SecureRandom.uuid
      created_by  = create(:user)
      location    = create(:location)
      start_date  = 2.days.from_now
      duration    = 3
      name        = "Created via RSpec request"
      description = "Created via RSpec request"

      params = {
        group_event: {
          uuid: uuid,
          name: name,
          description: description,
          created_by_id: created_by.id,
          location_id: location.id,
          start_date: start_date,
          duration_in_days: duration,
        }
      }

      post("/api/v1/group_events", params: params)

      # Validates response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      attributes = {
        uuid: uuid,
        name: name,
        status: "draft",
        description: description,
        created_by_id: created_by.id,
        location_id: location.id,
        start_date: start_date.to_s,
        duration: duration.days,
        end_date: (start_date + duration.days - 1.day).to_s,
      }

      validate_event_from_response(json_response, attributes)
    end

    pending "create group event fails with invalid attributes"
  end

  context "update" do
    pending "update fields :name, :description, :start_date, :end_date, :created_by_id, :location_id"
    pending "PUT"
    pending "PATCH"
  end

  context "destroy" do
    pending "Mark group event for deletion"
    pending "Do not allow already deleted record to be marked again"
  end

  context "restore" do
    pending "Restore group event which is marked for deletion"
    pending "Do not allow restoring record which is not marked for deletion"
  end

  context "publish" do
    pending "successfully publish a group event with valid fields"
    pending "reject publishing a group event with invalid values"
  end
end
