# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :app do
    name "MyString"
    memory 1
    instances ""
    env_variables "MyText"
    state "MyString"
  end
end
