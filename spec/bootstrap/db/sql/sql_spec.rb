require 'spec_helper'

describe "SQL" do

  def generate_data_for_time!(
      time,
      message = "Generated for #{time} in #{Time.zone}"
    )
    raise "Expected time with zone!" unless time.is_a?(ActiveSupport::TimeWithZone)
    date_values = {
      subject:        message,
      date_value:     time.to_date,
      datetime_value: time.to_datetime
    }
    date_model = DateDatum.create!(date_values)

    time_values = {
      subject:         message,
      time_value:      time.strftime("%H:%M:%S"), #strip to just time saved
      timestamp_value: time
    }
    time_model = TimeDatum.create!(time_values)
    return [date_model, time_model]
  end

  def rebase_database!(snapshot_generated_at, rebase_database_to)
    rebase_cmd = <<-SQL
    SELECT rebase_db_time(
      '#{snapshot_generated_at.to_s(:db)}'::timestamp with time zone,
      '#{rebase_database_to.to_s(:db)}'::timestamp with time zone
      );
    SQL

    ActiveRecord::Base.connection.execute(rebase_cmd)
  end

  RSpec.shared_examples "a database with all values set at" do
    context "date values" do
      subject { DateDatum.first }

      it "should match rebased date values" do
        expect(subject.date_value).to eq(expected_time_at.to_date)
      end

      it "should match rebased datetime values" do
        expect(subject.datetime_value.to_i).to eq(expected_time_at.to_i)
      end
    end

    context "time values" do
      subject { TimeDatum.first }

      # Possible future change to account for time change?
      it "should not have changed original time values (ignoring fractional precision of seconds)" do
        expect(subject.time_value.hour).to eq(database_values_set_at.hour)
        expect(subject.time_value.min).to eq(database_values_set_at.min)
        expect(subject.time_value.sec).to eq(database_values_set_at.sec)

        # Raw time values in Postgres (no date stored) are retreived with default date added
        # Year: 2000
        # The database has no date stored though
        expect(subject.time_value.year).to eq(2000)
        expect(database_values_set_at.year).not_to eq(2000)
      end

      it "should match rebased timestamp values" do
        expect(subject.timestamp_value.to_i).to eq(expected_time_at.to_i)
      end
    end
  end

  describe "postgres rebase_time" do
    before do
      ActiveRecord::Base.connection.execute("DROP FUNCTION IF EXISTS rebase_db_time(timestamp with time zone, timestamp with time zone)")

      expect(ActiveRecord::Base.connection.execute("select proname from pg_proc where proname = 'rebase_db_time';").values).not_to be_present

      # Load functions
      config = Bootstrap::Db::Config.load!
      driver = Bootstrap::Db::Postgres.new(config)
      driver.load_rebase_functions!

      # Ensure function is loaded
      expect(ActiveRecord::Base.connection.execute("select proname from pg_proc where proname = 'rebase_db_time';").values).to be_present
    end

    after do
      Timecop.return
      # Reset all data
      DateDatum.delete_all; TimeDatum.delete_all;
    end

    describe "with generated data" do
      let(:snapshot_generated_at)   { Time.zone.now }
      let(:database_values_set_at)  { Time.zone.now - 2.weeks }

      before do
        generate_data_for_time!(database_values_set_at)
      end

      describe "as is" do
        it_should_behave_like "a database with all values set at" do
          let(:expected_time_at) { database_values_set_at }
        end
      end

      describe "set before the database snapshot time" do
        let(:database_values_set_at) { Time.zone.now - 4.weeks - 3.days - 1.hour - 30.seconds }
        let(:snapshot_generated_at)  { Time.zone.now - 3.weeks }
        let(:rebase_database_to)     { Time.zone.now }

        before do
          rebase_database!(snapshot_generated_at, rebase_database_to)
        end

        it_should_behave_like "a database with all values set at" do
          let(:expected_time_at) { rebase_database_to - (1.week + 3.days + 1.hour + 30.seconds) }
        end
      end

      describe "set the same as database snapshot time" do
        let(:database_values_set_at) { Time.zone.now - 4.weeks - 3.days - 1.hour - 30.seconds }
        let(:snapshot_generated_at)  { Time.zone.now }
        let(:rebase_database_to)     { snapshot_generated_at }

        before do
          expect(snapshot_generated_at).to eq(rebase_database_to)
          rebase_database!(snapshot_generated_at, rebase_database_to)
        end

        it_should_behave_like "a database with all values set at" do
          let(:expected_time_at) { database_values_set_at }
        end
      end

      describe "set after the database snapshot time" do
        let(:snapshot_generated_at)  { Time.zone.now }
        let(:database_values_set_at) { Time.zone.now + (4.weeks + 3.days + 1.hour + 20.seconds) }
        let(:rebase_database_to)     { Time.zone.now + (1.week + 2.days + 2.hours + 10.seconds) }

        before do
          rebase_database!(snapshot_generated_at, rebase_database_to)
        end

        it_should_behave_like "a database with all values set at" do
          let(:expected_time_at) do
            (Time.zone.now + (1.week + 2.days + 2.hours + 10.seconds)) + (4.weeks + 3.days + 1.hour + 20.seconds)
          end
        end
      end

      context "set as a mix around the database snapshot time" do
        #Pick one date before and one datetime after
      end
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
