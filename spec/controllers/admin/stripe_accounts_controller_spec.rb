require 'spec_helper'

describe Admin::StripeAccountsController, type: :controller do

  describe "destroy_from_webhook" do
    let!(:stripe_account) { create(:stripe_account, stripe_user_id: "webhook_id") }
    let(:params) do
      {
        "format"=> "json",
        "id" => "evt_123",
        "object" => "event",
        "data" => { "object" => { "id" => "ca_9B" } },
        "type" => "account.application.deauthorized",
        "user_id" => "webhook_id"
      }
    end

    it "deletes Stripe accounts in response to a webhook" do
      post 'destroy_from_webhook', params
      expect(response.status).to eq 200
      expect(response.body).to eq "Account webhook_id deauthorized"
      expect(StripeAccount.all).not_to include stripe_account
    end

    context "when the user_id on the event does not match any known accounts" do
      before do
        params["user_id"] = "webhook_id1"
      end

      it "does nothing" do
        post 'destroy_from_webhook', params
        expect(response.status).to eq 400
        expect(StripeAccount.all).to include stripe_account
      end
    end

    context "when the event is not a deauthorize event" do
      before do
        params["type"] = "account.application.authorized"
      end

      it "does nothing" do
        post 'destroy_from_webhook', params
        expect(response.status).to eq 400
        expect(StripeAccount.all).to include stripe_account
      end
    end
  end

  describe "destroy" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:params) { { format: :json, id: "some_id"  } }

    context "when the specified stripe account doesn't exist" do
      it "raises an error?" do
        spree_delete :destroy, params
      end
    end

    context "when the specified stripe account exists" do
      let(:stripe_account) { create(:stripe_account, enterprise: enterprise) }

      before do
        # So that we can stub #deauthorize_and_destroy
        allow(StripeAccount).to receive(:find) { stripe_account }
        params[:id] = stripe_account.id
      end

      context "when I don't manage the enterprise linked to the stripe account" do
        let(:some_user) { create(:user) }

        before { allow(controller).to receive(:spree_current_user) { some_user } }

        it "redirects to unauthorized" do
          spree_delete :destroy, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "when I manage the enterprise linked to the stripe account" do
        before { allow(controller).to receive(:spree_current_user) { enterprise.owner } }

        context "and the attempt to deauthorize_and_destroy succeeds" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { stripe_account } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:success]).to eq "Stripe account disconnected."
          end
        end

        context "and the attempt to deauthorize_and_destroy fails" do
          before { allow(stripe_account).to receive(:deauthorize_and_destroy) { false } }

          it "redirects to unauthorized" do
            spree_delete :destroy, params
            expect(response).to redirect_to edit_admin_enterprise_path(enterprise)
            expect(flash[:error]).to eq "Failed to disconnect Stripe."
          end
        end
      end
    end
  end

  describe "verifying stripe account status with Stripe" do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:params) { { format: :json } }

    before do
      Stripe.api_key = "sk_test_12345"
      Spree::Config.set({stripe_connect_enabled: false})
    end

    context "where I don't manage the specified enterprise" do
      let(:user) { create(:user) }
      let(:enterprise2) { create(:enterprise) }
      before do
        user.owned_enterprises << enterprise2
        params.merge!({enterprise_id: enterprise.id})
        allow(controller).to receive(:spree_current_user) { user }
      end

      it "redirects to unauthorized" do
        spree_get :status, params
        expect(response).to redirect_to spree.unauthorized_path
      end
    end

    context "where I manage the specified enterprise" do
      before do
        params.merge!({enterprise_id: enterprise.id})
        allow(controller).to receive(:spree_current_user) { enterprise.owner }
      end

      context "but Stripe is not enabled" do
        it "returns with a status of 'stripe_disabled'" do
          spree_get :status, params
          json_response = JSON.parse(response.body)
          expect(json_response["status"]).to eq "stripe_disabled"
        end
      end

      context "and Stripe is enabled" do
        before { Spree::Config.set({stripe_connect_enabled: true}) }

        context "but it has no associated stripe account" do
          it "returns with a status of 'account_missing'" do
            spree_get :status, params
            json_response = JSON.parse(response.body)
            expect(json_response["status"]).to eq "account_missing"
          end
        end

        context "and it has an associated stripe account" do
          let!(:account) { create(:stripe_account, stripe_user_id: "acc_123", enterprise: enterprise) }

          context "which has been revoked or does not exist" do
            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(status: 404)
            end

            it "returns with a status of 'access_revoked'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "access_revoked"
            end
          end

          context "which is connected" do
            let(:stripe_account_mock) { {
              id: "acc_123",
              business_name: "My Org",
              charges_enabled: true,
              some_other_attr: "something"
            } }

            before do
              stub_request(:get, "https://api.stripe.com/v1/accounts/acc_123").to_return(body: JSON.generate(stripe_account_mock))
            end

            it "returns with a status of 'connected'" do
              spree_get :status, params
              json_response = JSON.parse(response.body)
              expect(json_response["status"]).to eq "connected"
              # serializes required attrs
              expect(json_response["business_name"]).to eq "My Org"
              # ignores other attrs
              expect(json_response["some_other_attr"]).to be nil
            end
          end
        end
      end
    end
  end
end