# Read about factories at https://github.com/thoughtbot/factory_girl
require 'faker'

FactoryGirl.define do
  factory :venue do
    association :host_kluuu, factory: :published_kluuu
    start_time Time.now + 1.week
    summary Faker::Lorem.paragraphs(1)
    description Faker::Lorem.paragraphs(2)
    title Faker::Lorem.sentence
    intro_video "MyString"
    duration 90
    #after(:create) do |venue|
    #  FactoryGirl.create_list(:venue_klu, 2, :venue => venue)
    #end
    trait :with_venue_klus do
      
      after(:create) do |venue|
        FactoryGirl.create_list(:venue_klu, 2, :venue => venue)
      end
  
    end
   
    factory :venue_with_klus, traits: [:with_venue_klus]
   
  end
end
