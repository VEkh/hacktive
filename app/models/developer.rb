# == Schema Information
#
# Table name: developers
#
#  id   :integer          not null, primary key
#  name :text             not null
#

class Developer < ActiveRecord::Base
  has_many :developer_activities

  def self.create_with_json(payload)
    self.create!(
      id: payload['id'],
      name: payload['login']
    )
  end

  def self.create_with_json_array(members)
    members.each do |member|
      self.create_with_json(member)
    end
  end
end

#------------------------------------------------------------------------------
# Developer
#
# Name SQL Type             Null    Default Primary
# ---- -------------------- ------- ------- -------
# id   integer              false           true   
# name text                 false           false  
#
#------------------------------------------------------------------------------