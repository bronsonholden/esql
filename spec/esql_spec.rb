RSpec.describe Esql do
  let(:parser) { Esql::Parser.new }
  let(:ast) { parser.parse(expression) }
  let(:scope) { Employee.all }
  let(:evaluation) { ast.evaluate(scope) }
  let(:evaluated_scope) { evaluation[0] }
  let(:evaluated_sql) { evaluation[1][1...-1] }

  describe 'evaluation' do

    # Test expressions that don't require database records
    describe 'primitives' do
      let(:evaluated_value) {
        ActiveRecord::Base.connection.execute(<<-SQL
          SELECT (#{evaluated_sql}) as result
        SQL
        ).first['result']
      }

      describe 'literals' do
        describe 'numbers' do
          {
            '1' => 1,
            '1e5' => 1e5,
            '-5.5' => -5.5
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end

        describe 'booleans' do
          # Heads up if testing outside of SQLite3: some databases serialize
          # Boolean values as 't' and 'f'.
          context 'true' do
            let(:expression) { 'true' }
            it 'returns correct value' do
              expect(evaluated_value).to eq(1)
            end
          end

          context 'false' do
            let(:expression) { 'false' }
            it 'returns correct value' do
              expect(evaluated_value).to eq(0)
            end
          end
        end

        describe 'strings' do
          [
            'string',
            'string"',
            '"enclosed"',
            "with'quotes"
          ].each do |str|
            context str.inspect do
              let(:expression) { str.inspect }
              it 'returns correct value' do
                expect(evaluated_value).to eq(str)
              end
            end
          end
        end
      end

      describe 'infix expressions' do
        let(:evaluated_value) {
          ActiveRecord::Base.connection.execute(<<-SQL
            SELECT (#{evaluated_sql}) as result
          SQL
          ).first['result']
        }

        describe '+' do
          {
            '1 + 2 + 3' => 6,
            '1 + (2 + 3)' => 6,
            '(1 + 2) + 3' => 6
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end

        describe '-' do
          {
            '1 - 2 - 3' => -4,
            '1 - (2 - 3)' => 2,
            '(1 - 2) - 3' => -4
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end

        describe '*' do
          {
            '1 * 2 * 3' => 6,
            '1 * (2 * 3)' => 6,
            '(1 * 2) * 3' => 6
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end

        describe '/' do
          {
            '20 / 10 / 2' => 1,
            '20 / (10 / 2)' => 4,
            '(20 / 10) / 2' => 1
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end
      end

      describe 'functions' do
        context 'invalid function' do
          let(:expression) { 'dance(1, 2, 3)' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::InvalidFunctionError)
          end
        end

        describe 'concat' do
          {
            'concat("a", "b", "c")' => 'abc',
            'concat(concat("a", "b"), "c")' => 'abc',
            'concat("a", 123)' => 'a123',
          }.each do |expr, value|
            context expr do
              let(:expression) { expr }
              it 'returns correct value' do
                expect(evaluated_value).to eq(value)
              end
            end
          end
        end
      end
    end

    describe 'record-based' do
      let(:column_alias) { 'generated' }
      let(:selected_scope) {
        evaluated_scope.select("(#{evaluated_sql}) as \"#{column_alias}\"")
      }
      let(:evaluated_record) { selected_scope.first }
      let(:evaluated_value) { evaluated_record.send(column_alias.to_sym) }

      describe 'attributes' do
        let(:scope) { Employee.all }
        let(:first_name) { 'John' }
        let(:last_name) { 'Doe' }

        before(:each) do
          create :employee, first_name: first_name, last_name: last_name
        end

        context 'invalid attribute' do
          let(:expression) { 'ssn' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::InvalidAttributeError)
          end
        end

        {
          'first_name' => :first_name,
          'last_name' => :last_name
        }.each do |expr, attr|
          context expr do
            let(:expression) { expr }
            it 'returns correct value' do
              expect(evaluated_value).to eq(self.send(attr))
            end
          end
        end
      end

      describe 'related attributes' do
        let(:scope) { Employee.all }
        let(:title) { 'FBI Agent' }
        let(:base_salary) { 50000 }
        let(:job) { create :job, title: title, base_salary: base_salary }

        before(:each) do
          create :employee, first_name: 'Burt', last_name: 'Macklin', job: job
        end

        context 'invalid relationship' do
          let(:expression) { 'pet.name' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::InvalidRelationshipError)
          end
        end

        context 'relationship misuse' do
          let(:expression) { 'job.count' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::RelationshipTypeError)
          end
        end

        {
          'job.title' => :title,
          'job.base_salary' => :base_salary
        }.each do |expr, attr|
          context expr do
            let(:expression) { expr }
            it 'returns correct value' do
              expect(evaluated_value).to eq(self.send(attr))
            end
          end
        end
      end

      describe 'related aggregates' do
        let(:scope) { Job.all }
        let(:count) { 10 }
        let(:job) { create :job }

        before(:each) do
          count.times do
            create :employee, job: job
          end
        end

        context 'invalid relationship' do
          let(:expression) { 'pets.count' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::InvalidRelationshipError)
          end
        end

        context 'relationship misuse' do
          let(:expression) { 'employees.name' }
          it 'raises error' do
            expect { evaluated_value }.to raise_error(Esql::RelationshipTypeError)
          end
        end

        describe 'count' do
          let(:expression) { 'employees.count' }

          it 'returns correct value' do
            expect(evaluated_value).to eq(count)
          end
        end
      end
    end
  end

  describe 'SQL' do
    shared_examples 'sql_output_match' do
      it 'outputs correct SQL' do
        expect(evaluated_sql).to eq(expected_sql)
      end
    end

    describe 'literals' do
      describe 'numbers' do
        {
          '1' => '1',
          '1e5' => '1e5'
        }.each do |expr, sql|
          context expr do
            let(:expression) { expr }
            let(:expected_sql) { expr }
            include_examples 'sql_output_match'
          end
        end
      end

      describe 'strings' do
        [
          'string',
          'string"',
          '"string"',
          "'str"
        ].each do |str|
          context str.inspect do
            let(:expression) { str.inspect }
            let(:expected_sql) { ActiveRecord::Base.connection.quote(str) }
            include_examples 'sql_output_match'
          end
        end
      end
    end
  end
end
