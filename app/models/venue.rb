class Venue < ActiveRecord::Base
  attr_accessible :title, :description, :host_kluuu_id, :intro_video, :start_time
  
  belongs_to :host_kluuu, :class_name => 'Kluuu'
  
  has_many :venue_klus, :dependent => :destroy
  has_many :klus, :class_name => 'Klu', :through => :venue_klus#, :uniq => true
  
  validates :host_kluuu, :title, :description, :start_time, :presence => true
  validates_uniqueness_of :venue_klu
  
  
  after_create :generate_notification
  
  def user_participates?(user)
    self.klus.collect { |k| k.user }.include?(user)
  end
  
  private
  
  def generate_notification
    
  end
end
