require 'target_my'

describe TargetMy do
  describe '#solution' do
    let(:app_link) { 'https://itunes.apple.com/en/app/angry-birds/id343200656?mt=8' }
    let(:app_name) { 'test_app' }
    let(:result) { TargetMy.new.solution(login, password, app_link, app_name) }

    context 'with correct login and password' do
      let(:login) { 'mailfortestapp@mail.ru' }
      let(:password) { '12345678d' }

      it 'return array with slot id of ad units' do
        expect(result[0][0]).to eq 'standard'
        expect(result[0][1]).to be_a Fixnum
        expect(result[1][0]).to eq 'fullscreen'
        expect(result[1][1]).to be_a Fixnum
      end
    end

    context 'with incorrect login and password' do
      let(:login) { 'oohyoutouchmytalala' }
      let(:password) { 'dingdingdong' }

      it 'raise error' do
        expect { result }.to raise_error RuntimeError, 'Auth failed'
      end
    end
  end
end
