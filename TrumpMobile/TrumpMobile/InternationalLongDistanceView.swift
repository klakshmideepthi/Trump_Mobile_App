import SwiftUI

struct InternationalLongDistanceView: View {
    @State private var selectedCountry = ""
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    
    // Sample of key countries with their limits
    let countryLimits = [
        CountryLimit(country: "Afghanistan", minutes: "30"),
        CountryLimit(country: "Afghanistan - Cellular", minutes: "40"),
        CountryLimit(country: "Algeria", minutes: "Unlimited"),
        CountryLimit(country: "Algeria - Cellular", minutes: "10"),
        CountryLimit(country: "Argentina", minutes: "Unlimited"),
        CountryLimit(country: "Argentina - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "Australia", minutes: "Unlimited"),
        CountryLimit(country: "Australia - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "Austria", minutes: "Unlimited"),
        CountryLimit(country: "Canada", minutes: "Unlimited"),
        CountryLimit(country: "China", minutes: "Unlimited"),
        CountryLimit(country: "China - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "France", minutes: "Unlimited"),
        CountryLimit(country: "France - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "Germany", minutes: "Unlimited"),
        CountryLimit(country: "Germany - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "India", minutes: "Unlimited"),
        CountryLimit(country: "India - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "Japan", minutes: "Unlimited"),
        CountryLimit(country: "Japan - Cellular", minutes: "Unlimited"),
        CountryLimit(country: "Mexico", minutes: "Unlimited"),
        CountryLimit(country: "South Korea", minutes: "Unlimited"),
        CountryLimit(country: "United Kingdom", minutes: "Unlimited"),
        CountryLimit(country: "United Kingdom - Cellular", minutes: "Unlimited")
    ]
    
    var filteredCountries: [CountryLimit] {
        if searchText.isEmpty {
            return countryLimits
        } else {
            return countryLimits.filter { $0.country.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Top spacing and close button
                    HStack {
                        Spacer()
                        Button("Close") {
                            // Add close action here - typically dismiss the view
                        }
                        .foregroundColor(.accentColor)
                        .font(.body)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("International Long Distance")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .background(GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        scrollOffset = geometry.frame(in: .global).minY
                                    }
                                    .onChange(of: geometry.frame(in: .global).minY) { value in
                                        scrollOffset = value
                                    }
                            })
                            
                            Text("Stay connected to family, friends, and business partners across the globe with Trump Mobile's International Long Distance service. Whether it's a quick call or regular communication, we make it easy and affordable to reach over 200 countries worldwide.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding(.horizontal)
                        
                        // Features Section
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureCard(
                                title: "Clear Rates. No Surprises.",
                                description: "As part of your Trump Mobile plan you receive unlimited international calling to over 100+ countries.",
                                icon: "chart.bar.fill"
                            )
                            
                            FeatureCard(
                                title: "Wide Global Coverage",
                                description: "Our International Long Distance service allows you to call landlines and mobile numbers in over 200 destinations, including North America, Europe, Asia, and more.",
                                icon: "globe"
                            )
                            
                            FeatureCard(
                                title: "Simple Activation",
                                description: "International Long Distance is automatically available on your Trump Mobile account. Just dial your international number and stay connected — no extra setup or activation needed.",
                                icon: "checkmark.circle.fill"
                            )
                            
                            FeatureCard(
                                title: "Stay Connected Worldwide",
                                description: "Whether you travel for business or stay in touch with loved ones abroad, Trump Mobile makes international calling easy, reliable, and affordable.",
                                icon: "phone.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Military Families Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("The Sacrifices of Our Military Families")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("At Trump Mobile, we honor the sacrifice of our military families. That's why our plan makes it easy and affordable for service members and their loved ones to stay connected — whether stationed at home or overseas. With free international texting, discounted international calling, and reliable global coverage, you can share life's important moments no matter where duty calls. Because when you're serving our country, you deserve to stay close to the ones who matter most.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Country Rates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Country Rates & Limits")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search countries...", text: $searchText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            .padding(.horizontal)
                            
                            // Country List
                            LazyVStack(spacing: 1) {
                                // Header
                                HStack {
                                    Text("Destination (Country)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("Max Cap (Minutes)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .background(Color(.systemGray5))
                                
                                ForEach(filteredCountries, id: \.country) { countryLimit in
                                    HStack {
                                        Text(countryLimit.country)
                                            .font(.body)
                                        Spacer()
                                        Text(countryLimit.minutes)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(countryLimit.minutes == "Unlimited" ? .accentColor : .primary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                    
                                    Divider()
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Contact Section
                        VStack(alignment: .center, spacing: 20) {
                            Text("Have Questions?")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Contact Customer Care for more details on rates, coverage, and supported countries.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                if let url = URL(string: "tel:8888786745") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call (888) 878-6745")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.accentColor, Color("AccentColor2")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .padding(.horizontal, 24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                }
                
            // Sticky Header
            if scrollOffset < -80 {
                VStack(spacing: 0) {
                    HStack {
                        Text("International Long Distance")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Close") {
                            // Add close action here - typically dismiss the view
                        }
                        .foregroundColor(.accentColor)
                        .font(.body)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: scrollOffset)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
    }
    
    struct FeatureCard: View {
        let title: String
        let description: String
        let icon: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    struct CountryLimit {
        let country: String
        let minutes: String
    }
    
    struct InternationalLongDistanceView_Previews: PreviewProvider {
        static var previews: some View {
            InternationalLongDistanceView()
        }
    }
}
