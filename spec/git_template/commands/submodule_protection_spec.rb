require 'spec_helper'
require 'git_template/commands/submodule_protection'
require 'git_template/models/result/iterate_command_result'

RSpec.describe GitTemplate::Command::SubmoduleProtection do
  let(:test_class) do
    Class.new do
      include GitTemplate::Command::SubmoduleProtection
    end
  end
  
  let(:instance) { test_class.new }
  
  describe '#is_submodule?' do
    context 'when .gitmodules exists' do
      before do
        allow(File).to receive(:exist?).with('.gitmodules').and_return(true)
        allow(File).to receive(:read).with('.gitmodules').and_return(gitmodules_content)
      end
      
      let(:gitmodules_content) do
        <<~GITMODULES
          [submodule "examples/rails8-simple"]
            path = examples/rails8-simple
            url = https://github.com/example/rails8-simple.git
          
          [submodule "examples/another-repo"]
            path = examples/another-repo
            url = https://github.com/example/another-repo.git
        GITMODULES
      end
      
      it 'returns true for existing submodule paths' do
        expect(instance.is_submodule?('examples/rails8-simple')).to be true
        expect(instance.is_submodule?('examples/another-repo')).to be true
      end
      
      it 'returns false for non-submodule paths' do
        expect(instance.is_submodule?('examples/not-a-submodule')).to be false
        expect(instance.is_submodule?('templated/examples/rails8-simple')).to be false
      end
    end
    
    context 'when .gitmodules does not exist' do
      before do
        allow(File).to receive(:exist?).with('.gitmodules').and_return(false)
      end
      
      it 'returns false for any path' do
        expect(instance.is_submodule?('examples/rails8-simple')).to be false
        expect(instance.is_submodule?('any/path')).to be false
      end
    end
  end
  
  describe '#check_submodule_protection' do
    before do
      allow(File).to receive(:exist?).with('.gitmodules').and_return(true)
      allow(File).to receive(:read).with('.gitmodules').and_return(gitmodules_content)
    end
    
    let(:gitmodules_content) do
      <<~GITMODULES
        [submodule "examples/rails8-simple"]
          path = examples/rails8-simple
          url = https://github.com/example/rails8-simple.git
      GITMODULES
    end
    
    context 'when path is a submodule' do
      it 'returns an error result' do
        result = instance.check_submodule_protection('examples/rails8-simple', 'test_command')
        
        expect(result).to be_a(GitTemplate::Models::Result::IterateCommandResult)
        expect(result.success).to be false
        expect(result.error_message).to include('Cannot run test_command on submodule')
        expect(result.error_message).to include('update-repo-template --path examples/rails8-simple')
      end
    end
    
    context 'when path is not a submodule' do
      it 'returns nil' do
        result = instance.check_submodule_protection('templated/examples/rails8-simple', 'test_command')
        expect(result).to be_nil
      end
    end
  end
end