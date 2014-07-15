require 'spec_helper'

describe "SQL" do
  describe "postgres rebase_time" do
    before(:all) do
      # Load functions
      config = Bootstrap::Db::Config.load!
      driver = Bootstrap::Db::Postgres.new(config)
      driver.load_rebase_functions!

      # Ensure function is loaded
      expect(ActiveRecord::Base.connection.execute("select proname from pg_proc where proname = 'rebase_db_time';").values).to be_present
    end


    context "when database values are in past" do
      it "should rebase all values to new point"
    end

    context "when database values are in future" do
      it "should rebase all values to new point"
    end

    context "when database values are current" do
      it "should maintain all values"
    end

    context "timezones" do
      context "generated in different zone to one being rebased to" do
        context "generated now" do
          context "when database is generated in -11 offset" do
            #loaded in -4
            #loaded in 0
            #loaded in 4
            #loaded in 13
          end
          context "when database is generated in +13 offset" do
            #loaded in -4
            #loaded in 0
            #loaded in 4
            #loaded in 13
          end
        end

        context "generated in past (1 week)" do
          context "when database is generated in -11 offset" do
            #loaded in -4
            #loaded in 0
            #loaded in 4
            #loaded in 13
          end
          context "when database is generated in +13 offset" do
            #loaded in -4
            #loaded in 0
            #loaded in 4
            #loaded in 13
          end
        end
      end
    end
  end
end
