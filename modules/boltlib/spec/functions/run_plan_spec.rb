require 'spec_helper'
require 'puppet_pal'

describe 'run_plan' do
  include PuppetlabsSpec::Fixtures
  before(:each) do
    Puppet[:tasks] = true
  end

  context "when invoked" do
    context 'can be called as' do
      it 'run_plan(name) referencing a plan defined in the manifest' do
        env = Puppet.lookup(:current_environment)
        result = Puppet::Pal.in_tmp_environment('pal_env', modulepath: env.modulepath) do |pal|
          pal.with_script_compiler do |compiler|
            compiler.evaluate_string(<<-CODE)
            plan run_me() { "worked1" }
            run_plan('run_me')
            CODE
          end
        end
        expect(result).to eql('worked1')
      end

      it 'run_plan(name) referencing an autoloaded plan in a module' do
        is_expected.to run.with_params('test::run_me').and_return('worked2')
      end

      it 'run_plan(name, hash) where hash is mapping argname to value' do
        is_expected.to run.with_params('test::run_me_int', 'x' => 3).and_return(3)
      end
    end

    context 'using the name of the module' do
      it 'the plans/init.pp is found and called' do
        is_expected.to run.with_params('test').and_return('worked4')
      end
    end

    context 'handles exceptions by' do
      it 'failing with error for non-existent plan name' do
        is_expected.to run.with_params('not_a_plan_name').and_raise_error(/Unknown plan/)
      end

      it 'failing with type mismatch error if given args does not match parameters' do
        is_expected.to run.with_params('test::run_me_int', 'x' => 'should not work')
                          .and_raise_error(/expects an Integer value/)
      end
    end
  end
end
