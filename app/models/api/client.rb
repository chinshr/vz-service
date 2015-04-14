class Api::Client < ActiveRecord::Base
  self.table_name = "api_clients"
  KEY_SIZE = 44

  belongs_to :platform
  has_many :devices, class_name: "Api::Device"
  has_many :client_accesses, :through => :devices do
    def create(client_access_attributes)
      device_name = client_access_attributes[:device_name]
      client_access_attributes.except!(:device_name)
      cla = Api::ClientAccess.create(client_access_attributes)
      if (device = Api::Device.find_by_uid(client_access_attributes[:device_uid]))
        device.client_access = cla
        device.client = self.proxy_association.owner
        device.save!
      else
        if client_access_attributes[:device_uid]
          uid = client_access_attributes[:device_uid]
        else
          uid = client_access_attributes[:device_user_uid]
        end
        Api::Device.where(uid: uid, device_name: device_name).scoping do
          self.concat(cla)
        end
      end
      return cla
    end
  end

  validates :name, presence: true, uniqueness: {case_sensitive: true},
    length: {minimum: 1, maximum: 250}
  validates :key, presence: true, length: {minimum: 40}

  class << self
    def generate_key
      alphanumeric_ascii = (48..57).to_a + (65..90).to_a + (97..122).to_a
      KEY_SIZE.times.map { alphanumeric_ascii.sample.chr }.join
    end
  end
end