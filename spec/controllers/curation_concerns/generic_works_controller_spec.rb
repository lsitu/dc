require 'rails_helper'
require 'controllers/concerns/set_units_behavior'

RSpec.describe CurationConcerns::GenericWorksController, type: :controller do
  let(:user) { create(:user) }
  let(:params) { { title: ['My work'], creator: ['Creator'], keyword: ['foo'], rights: ['http://creativecommons.org/licenses/by-sa/3.0/us/'], unit: 'myunit' } }

  before do
    sign_in user
  end

  describe "modules" do
    it { is_expected.to include_module(CurationConcerns::CurationConcernController) }
    it { is_expected.to include_module(Sufia::WorksControllerBehavior) }
  end

  it_behaves_like "set_units_behavior" do
    let(:model) { create(:generic_work, unit: unit1.key) }
  end

  describe "GET #new" do
    it "assigns all the user's units to @units" do
      create(:unit)
      unit2 = create(:unit, key: 'unit2')
      unit3 = create(:unit, key: 'unit3')
      create(:membership, user: user, unit: unit2)
      create(:membership, user: user, unit: unit3)

      get :new

      expect(assigns(:units)).to eq [unit2, unit3]
    end
  end

  describe "POST #create" do
    let!(:unit) { create(:unit) }
    let!(:membership) { create(:membership, unit: unit, user: user) }

    context "when user is a member of unit" do
      it "creates a new work" do
        expect { post :create, generic_work: params }
          .to change(GenericWork, :count).by 1
      end
    end

    context "when user is not a member of unit" do
      it "refuses to create work" do
        key = 'notmyunit'
        create(:unit, key: key)

        expect { post :create, generic_work: params.merge(unit: key) }
          .not_to change(GenericWork, :count)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:unit) { create(:unit) }
    let!(:generic_work) { create(:generic_work, user: user, unit: unit.key) }

    context 'user is a manager in generic work unit' do
      let!(:membership) { create(:membership, user: user, unit: unit, level: Membership::MANAGER_LEVEL) }

      it "destroys the requested generic work" do
        expect { delete :destroy, id: generic_work }
          .to change(GenericWork, :count).by(-1)
      end

      it "redirects to the catalog index" do
        delete :destroy, id: generic_work
        expect(response).to redirect_to '/catalog'
      end
    end

    context 'user is a data entry member of generic work unit' do
      let!(:membership) { create(:membership, user: user, unit: unit, level: Membership::DATA_ENTRY_LEVEL) }

      it "does not destroy the requested generic work" do
        expect { delete :destroy, id: generic_work }
          .to change(GenericWork, :count).by(0)
      end
    end

    context 'user is not a member of generic work unit' do
      it "does not destroy the requested generic work" do
        expect { delete :destroy, id: generic_work }
          .to change(GenericWork, :count).by(0)
      end
    end
  end
end
