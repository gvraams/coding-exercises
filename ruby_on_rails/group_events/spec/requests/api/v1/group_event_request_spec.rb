require 'rails_helper'

PATH = "/api/v1/group_events"

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
    it "returns active group events count" do
      group_event = create(:group_event)
      get("#{PATH}/count", headers: headers)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({ "count" => 1 })
    end

    it "excludes records marked for deletion" do
      group_event = create(:group_event)
      group_event.soft_destroy

      get("#{PATH}/count", headers: headers)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({ "count" => 0 })
    end
  end

  context "index" do
    it "checks HTTP response & status" do
      group_event = create(:group_event)
      attributes  = group_event.attributes
      get(PATH, headers: headers)

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      validate_event_from_response(json_response.first, group_event.attributes)
    end

    it "checks limit, offset & default order (:created_at => :asc)" do
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
      get(PATH, headers: headers)

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(3)

      # --- GET#index with :limit
      get(PATH, headers: headers, params: { limit: 1 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(first.uuid)

      # --- GET#index with :offset
      get(PATH, headers: headers, params: { offset: 2 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(third.uuid)

      # --- GET#index with both :limit & :offset
      get(PATH, headers: headers, params: { limit: 1, offset: 1 })

      # Validates HTTP Response status
      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response.length).to eq(1)
      expect(json_response.first["uuid"]).to eq(second.uuid)
    end
  end

  context "show" do
    it "returns 404 if record could not be found" do
      get("#{PATH}/#{SecureRandom.uuid}", headers: headers)

      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore"
      })
    end

    it "checks HTTP response & status" do
      group_event = create(:group_event)
      attributes  = group_event.attributes
      get("#{PATH}/#{group_event.uuid}", headers: headers)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      validate_event_from_response(json_response, group_event.attributes)
    end
  end

  context "create" do
    it "group event with valid attributes" do
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

      post(PATH, params: params)

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

    it "group event failure with invalid attributes" do
      params = {
        group_event: {
          uuid: SecureRandom.uuid,
          name: "Created via RSpec request",
          description: "Created via RSpec request",
          start_date: 2.days.ago,
          duration_in_days: 0,
        }
      }

      post(PATH, params: params)
      expect(response).to have_http_status(422)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event could not be created",
        "errors" => ["Created by must exist", "Location must exist"],
      })
    end
  end

  context "update" do
    it "returns 404 if record could not be found" do
      put("#{PATH}/#{SecureRandom.uuid}", headers: headers, params: {})

      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore"
      })

      patch("#{PATH}/#{SecureRandom.uuid}", headers: headers, params: {})

      expect(response).to have_http_status(404)
      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore"
      })
    end

    it "fields :name, :description, :start_date, :end_date, :created_by_id, :location_id" do
      group_event = create(:group_event)
      user        = create(:user, { email: "newemail@gmail.com" })
      location    = create(:location, { name: "Bangalore" })

      params = {
        group_event: {
          uuid: group_event.uuid,
          start_date: 3.days.from_now,
          end_date: 4.days.from_now,
          name: "New name",
          description: "New description",
          created_by_id: user.id,
          location_id: location.id,
        }
      }

      attributes = {
        uuid: group_event.uuid,
        name: "New name",
        description: "New description",
        start_date: 3.days.from_now.to_s,
        end_date: 4.days.from_now.to_s,
        duration: 2.days,
        status: "draft",
        created_by_id: user.id,
        location_id: location.id,
      }

      put("#{PATH}/#{group_event.uuid}", params: params)

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      validate_event_from_response(json_response, attributes)
    end

    it "does not allow invalid fields to be updated" do
      group_event = create(:group_event)
      user        = create(:user, { email: "newemail@gmail.com" })
      location    = create(:location, { name: "Bangalore" })

      params = {
        group_event: {
          uuid: group_event.uuid,
          start_date: 4.days.from_now,
          end_date: 2.days.from_now,
          name: "New name",
          description: "New description",
          created_by_id: user.id,
          location_id: location.id,
        }
      }

      put("#{PATH}/#{group_event.uuid}", params: params)
      expect(response).to have_http_status(422)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event could not be updated",
        "errors" => ["End date cannot be lesser than start date"],
      })
    end
  end

  context "destroy" do
    it "returns 404 if record could not be found" do
      delete("#{PATH}/#{SecureRandom.uuid}")

      expect(response).to have_http_status(404)

      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end

    it "marks group event for deletion" do
      group_event = create(:group_event)
      delete("#{PATH}/#{group_event.uuid}")

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event is deleted",
      })
    end

    it "returns 404 if tried to delete an already deleted record" do
      group_event = create(:group_event)
      group_event.soft_destroy
      delete("#{PATH}/#{group_event.uuid}")

      expect(response).to have_http_status(404)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end
  end

  context "really_destroy" do
    it "returns 404 if record could not be found" do
      delete("#{PATH}/#{SecureRandom.uuid}/really_delete")

      expect(response).to have_http_status(404)

      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end

    it "marks group event for deletion" do
      group_event = create(:group_event)
      group_event.soft_destroy
      delete("#{PATH}/#{group_event.uuid}/really_delete")

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event is deleted",
      })
    end

    it "returns 404 if tried to delete a record that is not marked for deletion" do
      group_event = create(:group_event)
      delete("#{PATH}/#{group_event.uuid}/really_delete")

      expect(response).to have_http_status(404)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end
  end

  context "restore" do
    it "returns 404 if record could not be found" do
      put("#{PATH}/#{SecureRandom.uuid}/restore")

      expect(response).to have_http_status(404)

      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end

    it "restores group event which was deleted" do
      group_event = create(:group_event)
      group_event.soft_destroy
      put("#{PATH}/#{group_event.uuid}/restore")

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event is restored",
      })
    end

    it "returns 404 if tried to restore a regular record" do
      group_event = create(:group_event)
      group_event.soft_destroy
      delete("#{PATH}/#{group_event.uuid}")

      expect(response).to have_http_status(404)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end
  end

  context "publish" do
    it "returns 404 if record could not be found" do
      put("#{PATH}/#{SecureRandom.uuid}/publish")

      expect(response).to have_http_status(404)

      expect(JSON.parse(response.body)).to eq({
        "message" => "This group event does not seem to exist anymore",
      })
    end

    it "publishes group event" do
      group_event = create(:group_event)
      put("#{PATH}/#{group_event.uuid}/publish")

      expect(response).to have_http_status(200)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "message" => "Group event is published",
      })
    end

    it "does not publish if invalid fields are supplied" do
      group_event = create(:group_event, {
        duration: nil,
        start_date: nil,
        end_date: nil,
      })

      put("#{PATH}/#{group_event.uuid}/publish")

      expect(response).to have_http_status(422)
      json_response = JSON.parse(response.body)

      expect(json_response).to eq({
        "errors" => [
          "Duration can't be blank",
          "Start date can't be blank",
          "End date can't be blank",
        ],
        "message" => "Group event could not be published",
      })
    end
  end
end
