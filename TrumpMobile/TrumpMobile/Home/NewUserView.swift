import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FeatureRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .frame(width: 24, height: 24)
        .foregroundStyle(
          LinearGradient(
            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
            startPoint: .leading,
            endPoint: .trailing
          )
        )
      Text(text)
        .font(.body)
        .foregroundColor(.trumpText)
    }
  }
}

struct NewUserView: View {
  var onLogout: (() -> Void)? = nil

  @State private var isLoading = false
  @State private var errorMessage: String? = nil
  @State private var showInternationalDetails = false
  @State private var isMenuOpen = false
  @EnvironmentObject private var navigationState: NavigationState
  @State private var selectedPlan: Plan? = nil
  @State private var planNavIsActive = false
  private let plans = PlansData.allPlans

  private func isPlanActiveBinding(for plan: Plan) -> Binding<Bool> {
    Binding(
      get: { self.selectedPlan?.id == plan.id && self.planNavIsActive },
      set: { val in if !val { self.selectedPlan = nil } }
    )
  }

  private func handlePlanTap(_ plan: Plan) {
    self.selectedPlan = plan
    self.planNavIsActive = true
  }

  private func planRow(for plan: Plan) -> some View {
    NavigationLink(
      destination: PlanDetailView(
        plan: plan
      ),
      isActive: isPlanActiveBinding(for: plan)
    ) {
      PlanCardView(plan: plan)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .simultaneousGesture(
      TapGesture().onEnded { handlePlanTap(plan) }
    )
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.trumpBackground.ignoresSafeArea()
        VStack(spacing: 0) {
          // HEADER
          AppHeader {
            Image("Trump_Mobile_logo_gold")
              .resizable()
              .aspectRatio(80.0/23.0, contentMode: .fit)
              .frame(height: 25)
              .clipped()
            Spacer()
            Button(action: {
              withAnimation(.easeInOut(duration: 0.3)) {
                isMenuOpen = true
              }
            }) {
              Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundStyle(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
            }
          }

          // SCROLLABLE CONTENT
          ScrollView {
            VStack(alignment: .center, spacing: 16) {
              Text("Welcome to TelcoFi")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 16)

              Text("Available Plans")
                .font(.title2)
                .padding(.bottom, 4)

              VStack(spacing: 16) {
                ForEach(plans) { plan in
                  self.planRow(for: plan)
                }
              }
            }
            .padding(.horizontal, 16)
          }
        }
        .ignoresSafeArea(.keyboard)

        // SHEETS
        .sheet(isPresented: $showInternationalDetails) {
          NavigationView { InternationalLongDistanceView() }
        }
        .sheet(isPresented: $navigationState.showPreviousOrders) {
          NavigationView { PreviousOrdersView(orders: []) }
        }
        .sheet(isPresented: $navigationState.showContactInfoDetail) {
          NavigationView { ContactInfoDetailView() }
        }
        .sheet(isPresented: $navigationState.showInternationalLongDistance) {
          NavigationView { InternationalLongDistanceView() }
        }
        .sheet(isPresented: $navigationState.showPrivacyPolicy) {
          PrivacyPolicyView()
        }
        .sheet(isPresented: $navigationState.showTermsAndConditions) {
          TermsAndConditionsView()
        }

        // Hamburger Menu Overlay
        HamburgerMenuView(isMenuOpen: $isMenuOpen)

        // Loading Indicator
        if isLoading {
          VStack {
            Spacer()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(2.0)
            Spacer()
          }
          .transition(.opacity)
          .zIndex(1)
        }
      }
    }
  }
}

struct NewUserView_Previews: PreviewProvider {
  static var previews: some View {
    NewUserView()
  }
}