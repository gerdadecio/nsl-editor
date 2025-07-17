require 'rails_helper'

RSpec.describe Tabs::Permissions::BasePermissionService, type: :service do
  let(:session_user) { double('SessionUser', username: 'test_user') }
  let(:resource) { double('Resource', id: 1) }
  let(:service) { described_class.new(session_user: session_user, resource: resource) }

  describe '#initialize' do
    it 'assigns session_user and resource' do
      expect(service.session_user).to eq(session_user)
      expect(service.resource).to eq(resource)
    end

    it 'allows nil resource' do
      service_without_resource = described_class.new(session_user: session_user)
      expect(service_without_resource.resource).to be_nil
    end
  end

  describe 'validations' do
    context 'with valid params' do
      it 'is valid' do
        expect(service.valid?).to be true
      end
    end

    context 'without session_user' do
      let(:service) { described_class.new(session_user: nil, resource: resource) }

      it 'is invalid' do
        expect(service.valid?).to be false
        expect(service.errors[:session_user]).to include("SessionUser is required")
      end
    end
  end

  describe '#execute' do
    context 'with valid service' do
      it 'returns self as result' do
        result = service.execute
        expect(result).to eq(service)
        expect(service.result).to eq(service)
      end
    end

    context 'with invalid service' do
      let(:service) { described_class.new(session_user: nil, resource: resource) }

      it 'returns nil when invalid' do
        result = service.execute
        expect(result).to be_nil
      end
    end
  end

  describe '#can_show_tab?' do
    let(:ability) { double('Ability') }
    let(:registry) { double('Registry') }

    before do
      allow(service).to receive(:registry).and_return(registry)
      allow(Ability).to receive(:new).with(session_user).and_return(ability)
      allow(service).to receive(:resource_type_key).and_return('test_resource')
    end

    context 'with blank tab_id' do
      it 'returns true' do
        expect(service.can_show_tab?('')).to be true
        expect(service.can_show_tab?(nil)).to be true
      end
    end

    context 'with no permission configured' do
      it 'returns true when no permission is found' do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(nil)
        expect(service.can_show_tab?('test_tab')).to be true
      end
    end

    context 'with simple permission' do
      let(:permission) { { ability: 'read', action: 'show' } }

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
      end

      it 'returns true when permission is granted' do
        allow(ability).to receive(:can?).with('read', 'show').and_return(true)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when permission is denied' do
        allow(ability).to receive(:can?).with('read', 'show').and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end
    end

    context 'with resource-based permission' do
      let(:permission) { { ability: 'update', resource: '@resource' } }

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
      end

      it 'returns true when resource permission is granted' do
        allow(ability).to receive(:can?).with('update', resource).and_return(true)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when resource is nil' do
        service_without_resource = described_class.new(session_user: session_user)
        allow(service_without_resource).to receive(:registry).and_return(registry)
        allow(service_without_resource).to receive(:resource_type_key).and_return('test_resource')
        
        expect(service_without_resource.can_show_tab?('test_tab')).to be false
      end
    end

    context 'with class-based permission' do
      let(:permission) { { ability: 'create', resource: 'TestClass' } }

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
        stub_const('TestClass', Class.new)
      end

      it 'returns true when class permission is granted' do
        allow(ability).to receive(:can?).with('create', TestClass).and_return(true)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when class permission is denied' do
        allow(ability).to receive(:can?).with('create', TestClass).and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end

      it 'returns false when class does not exist' do
        permission[:resource] = 'NonExistentClass'
        allow(Rails.logger).to receive(:error)
        expect(service.can_show_tab?('test_tab')).to be false
      end
    end

    context 'with exclude permission' do
      let(:permission) do
        {
          ability: 'create',
          resource: 'Instance',
          exclude: { ability: 'admin', action: 'manage' }
        }
      end

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
        stub_const('Instance', Class.new)
      end

      it 'returns true when main permission is granted and exclude is not' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(true)
        allow(ability).to receive(:can?).with('admin', 'manage').and_return(false)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when main permission is denied' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end

      it 'returns false when exclude permission is granted' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(true)
        allow(ability).to receive(:can?).with('admin', 'manage').and_return(true)
        expect(service.can_show_tab?('test_tab')).to be false
      end
    end

    context 'with additional permission' do
      let(:permission) do
        {
          ability: 'create',
          resource: 'Instance',
          additional: { ability: 'special', action: 'feature' }
        }
      end

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
        stub_const('Instance', Class.new)
      end

      it 'returns true when both main and additional permissions are granted' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(true)
        allow(ability).to receive(:can?).with('special', 'feature').and_return(true)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when main permission is denied' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end

      it 'returns false when additional permission is denied' do
        allow(ability).to receive(:can?).with('create', Instance).and_return(true)
        allow(ability).to receive(:can?).with('special', 'feature').and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end
    end

    context 'with simple ability permission' do
      let(:permission) { { ability: 'admin' } }

      before do
        allow(registry).to receive(:permission_for).with('test_resource', 'test_tab').and_return(permission)
      end

      it 'returns true when ability is granted' do
        allow(ability).to receive(:can?).with('admin').and_return(true)
        expect(service.can_show_tab?('test_tab')).to be true
      end

      it 'returns false when ability is denied' do
        allow(ability).to receive(:can?).with('admin').and_return(false)
        expect(service.can_show_tab?('test_tab')).to be false
      end
    end
  end

  describe '#resource_type_key' do
    it 'raises NotImplementedError' do
      expect { service.send(:resource_type_key) }.to raise_error(NotImplementedError, "Subclasses must implement resource_type_key method")
    end
  end

  describe '#registry' do
    it 'returns the Registry class' do
      expect(service.send(:registry)).to eq(Tabs::Permissions::Registry)
    end
  end
end