require "test_helper"

class TriggersTest < Minitest::Test
  attr_reader :triggers


  context "in the general case" do
    setup do
      @triggers = Hayfork.maintain(Haystack) do
        foreach Book do |index|
          index.insert(:title)
        end
      end
    end

    context "#create" do
      should "produce the SQL that will create the appropriate triggers for the specified table" do
        any_instance_of(Hayfork::Statement) do |statement|
          stub(statement).insert.stub!.to_sql.returns("<!-- INSERT -->")
          stub(statement).update.stub!.to_sql.returns("<!-- UPDATE -->")
          stub(statement).delete.stub!.to_sql.returns("<!-- DELETE -->")
          stub(statement).may_change_on_update?.returns(true)
        end

        assert_equal <<~SQL, triggers.create
          CREATE FUNCTION maintain_books_in_haystack() RETURNS trigger AS $$
          BEGIN
            IF TG_OP = 'DELETE' THEN
              <!-- DELETE -->
              RETURN OLD;
            ELSIF TG_OP = 'UPDATE' THEN
              <!-- UPDATE -->
              RETURN NEW;
            ELSIF TG_OP = 'INSERT' THEN
              <!-- INSERT -->
              RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
          END;
          $$ LANGUAGE plpgsql;
          CREATE TRIGGER maintain_books_in_haystack_trigger BEFORE INSERT OR UPDATE OR DELETE ON books
          FOR EACH ROW EXECUTE PROCEDURE maintain_books_in_haystack();
        SQL
      end

      should "skip UPDATE logic if none of the values used to populate the Haystack will change" do
        any_instance_of(Hayfork::Statement) do |statement|
          stub(statement).insert.stub!.to_sql.returns("<!-- INSERT -->")
          stub(statement).update.stub!.to_sql.returns("<!-- UPDATE -->")
          stub(statement).delete.stub!.to_sql.returns("<!-- DELETE -->")
          stub(statement).may_change_on_update?.returns(false)
        end

        assert_equal <<~SQL, triggers.create
          CREATE FUNCTION maintain_books_in_haystack() RETURNS trigger AS $$
          BEGIN
            IF TG_OP = 'DELETE' THEN
              <!-- DELETE -->
              RETURN OLD;
            ELSIF TG_OP = 'UPDATE' THEN
              -- nothing to update
              RETURN NEW;
            ELSIF TG_OP = 'INSERT' THEN
              <!-- INSERT -->
              RETURN NEW;
            END IF;
            RETURN NULL; -- result is ignored since this is an AFTER trigger
          END;
          $$ LANGUAGE plpgsql;
          CREATE TRIGGER maintain_books_in_haystack_trigger BEFORE INSERT OR UPDATE OR DELETE ON books
          FOR EACH ROW EXECUTE PROCEDURE maintain_books_in_haystack();
        SQL
      end
    end

    context "#drop" do
      should "produce the SQL that will delete a trigger for the specified table" do
        assert_equal <<~SQL, triggers.drop
          DROP FUNCTION IF EXISTS maintain_books_in_haystack() CASCADE;
        SQL
      end
    end

    context "#rebuild" do
      should "produce the SQL that will rebuild the haystack given the new logic" do
        any_instance_of(Hayfork::Statement) do |statement|
          stub(statement).insert.stub!.to_sql.returns("<!-- INSERT -->")
        end

        assert_equal <<~SQL, triggers.rebuild
          TRUNCATE haystack;
          <!-- INSERT -->
        SQL
      end
    end
  end


end
