require 'target_my'

describe TargetMy do
  let(:app_link) { 'https://itunes.apple.com/en/app/angry-birds/id343200656?mt=8' }
  let(:app_name) { 'test_app' }
  let(:login) { '' }
  let(:password) { '' }
  let(:instance) { TargetMy.new(login, password, app_link, app_name) }

  describe '#create_and_bind_app' do
    context 'with incorrect login and password' do
      let(:login) { 'oohyoutouchmytalala' }
      let(:password) { 'dingdingdong' }

      it 'raise error' do
        expect { instance.create_and_bind_app }.to raise_error RuntimeError, 'Auth failed'
      end

      it 'does not set app_id for instance' do
        expect { instance.create_and_bind_app rescue nil }.to_not change(instance, :app_id)
      end
    end

    context 'with correct login and password' do
      it 'set app_id for instance' do
        instance.create_and_bind_app
        expect(instance).to have_attributes(:app_id => an_instance_of(Fixnum))
      end

      context 'if instance already have app' do
        it 'raise error' do
          instance.create_and_bind_app
          expect { instance.create_and_bind_app }.to raise_error RuntimeError, 'Application already exists and attached'
        end
      end
    end
  end

  describe '#add_fullscreen_block' do
    context 'if app does not added' do
      it 'raise error' do
        expect { instance.add_fullscreen_block }.to raise_error RuntimeError, 'Application does not created'
      end
    end
  end

  describe '#slot_ids' do
    context 'if app does not added' do
      it 'raise error' do
        expect { instance.add_fullscreen_block }.to raise_error RuntimeError, 'Application does not created'
      end
    end

    context 'if app added' do
      it 'return hash with slot_ids and types of blocks' do
        instance.create_and_bind_app
        hash = instance.slot_ids
        expect(hash).to be_a Hash
        expect(hash.keys[0]).to be_a Fixnum
        expect(hash.values[0]).to eq 'standard'
      end
    end
  end
end
