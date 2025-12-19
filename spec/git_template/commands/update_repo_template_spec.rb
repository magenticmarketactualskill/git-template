require 'spec_helper'
require 'git_template/commands/submodule_protection'

RSpec.describe GitTemplate::Command::UpdateRepoTemplate do
  let(:test_class) do
    Class.new do
      include GitTemplate::Command::SubmoduleProtection
    end
  end
  
  let(:instance) { test_class.new }
  
  describe 'submodule detection' do
    
    context 'when path is a valid submodule' do
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
      
      it 'identifies the path as a submodule' do
        expect(instance.is_submodule?('examples/rails8-simple')).to be true
      end
    end
    
    context 'when path is not a submodule' do
      before do
        allow(File).to receive(:exist?).with('.gitmodules').and_return(true)
        allow(File).to receive(:read).with('.gitmodules').and_return(gitmodules_content)
      end
      
      let(:gitmodules_content) do
        <<~GITMODULES
          [submodule "examples/other-repo"]
            path = examples/other-repo
            url = https://github.com/example/other-repo.git
        GITMODULES
      end
      
      it 'identifies the path as not a submodule' do
        expect(instance.is_submodule?('examples/rails8-simple')).to be false
      end
    end
    
    context 'when .gitmodules does not exist' do
      before do
        allow(File).to receive(:exist?).with('.gitmodules').and_return(false)
      end
      
      it 'identifies any path as not a submodule' do
        expect(instance.is_submodule?('examples/rails8-simple')).to be false
      end
    end
  end
end