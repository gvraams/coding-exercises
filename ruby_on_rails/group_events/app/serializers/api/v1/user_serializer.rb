class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :email
end
