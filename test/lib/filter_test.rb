require 'test_helper'

class TempModel < ActiveRecord::Base
  self.table_name = 'documents' # use documents just for test
  include Model::Filter
  
  filtered_scopes :active, :sort_order
  scope :active, lambda { |param| where(:locale => "en-US")}
  scope :sort_order, lambda { |param| 
    case param.downcase.to_s
    when "id"
      order(self.arel_table[:id].asc.to_sql)
    when "title"
      order(self.arel_table[:title].asc.to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  
  after_initialize :build_required_attributes
  
  protected 
  
  def build_required_attributes
    self.slug = SecureRandom.uuid
  end
end

class ChildTempModel < TempModel
  self.inheritance_column = :non_sti
  filtered_scopes :last_created
  scope :last_created, lambda { |param| order("created_at desc").limit(1)}
end

class ChildScopeOnlyTempModel < TempModel
  self.inheritance_column = :non_sti
  filtered_scopes :last_created, :only => true
  scope :last_created, lambda { |param| order("created_at desc").limit(1)}
end

class FilterTest < ActiveSupport::TestCase
  should "return scopes list" do
    assert_equal [:active, :offset, :limit, :sort_order].to_set, TempModel.scopes.to_set
  end

  should "return scopes list of from parent class and itself" do
    assert_equal [:last_created, :active, :offset, :limit, :sort_order].to_set, ChildTempModel.scopes.to_set
  end

  should "return scopes list of only the ones listed in the model and not the parent class" do
    assert_equal [:last_created, :offset, :limit].to_set, ChildScopeOnlyTempModel.scopes.to_set
  end

  context "filter" do
    should "incorect scope should raise exception on wrong parameter" do
      assert_raise ArgumentError do
        TempModel.filter(1)
      end
    end

    should "ignore wrong filter" do
      TempModel.create
      assert_equal TempModel.filter({"wrong"=>1}).load.to_set, TempModel.filter({}).load.to_set
    end

    should "scope depending on params" do
      TempModel.create
      assert_equal TempModel.filter({"active"=>1}).load.to_set, TempModel.filter({}).load.to_set
    end

    should "sort by :title and :id" do
      m1 = TempModel.create(:title=>"B") #1
      m2 = TempModel.create(:title=>"A") #2
      m3 = TempModel.create(:title=>"A") #3
      assert_equal TempModel.filter({"sort_order" => ["title","id"]}).to_set, [m2, m3, m1].to_set
    end

    should "negative offset should be 0" do
      m1 = TempModel.create(:title=>"B") #1
      m2 = TempModel.create(:title=>"A") #2
      m3 = TempModel.create(:title=>"A") #3

      assert_equal TempModel.filter({:offset=>-1}).to_set, [m1, m2, m3].to_set
    end

    should "not integer offset should be 0" do
      m1 = TempModel.create(:title=>"B") #1
      m2 = TempModel.create(:title=>"A") #2
      m3 = TempModel.create(:title=>"A") #3

      assert_equal TempModel.filter({:offset=>'a'}).to_set, [m1, m2, m3].to_set
    end
  end
end