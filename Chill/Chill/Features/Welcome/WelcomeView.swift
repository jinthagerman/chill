import SwiftUI
import UIKit

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: WelcomeViewModel = WelcomeViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundView

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: Spacing.stackLarge * 2) {
                    header
                    ctaSection
                }
                .padding(.horizontal, Spacing.stackLarge)
                .padding(.vertical, Spacing.stackLarge)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .accessibilityElement(children: .contain)
        }
        .onAppear {
            if reduceMotion {
                viewModel.beginAnimationsIfNeeded()
            } else {
                withAnimation(.easeOut(duration: 0.45)) {
                    viewModel.beginAnimationsIfNeeded()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .center, spacing: Spacing.stackSmall) {
            Text(viewModel.content.headline)
                .font(.system(size: 140, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
                .multilineTextAlignment(.center)

            Text(viewModel.content.subheadline)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(Spacing.stackSmall)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("welcomeSubheadline")
        }
        .frame(maxWidth: .infinity)
    }

    private var ctaSection: some View {
        VStack(alignment: .center, spacing: Spacing.stackMedium) {
            ForEach(viewModel.primaryButtons) { configuration in
                Button(action: { viewModel.handleTap(for: configuration.role) }) {
                    Text(configuration.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.stackSmall)
                        .padding(.horizontal, Spacing.stackSmall)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(configuration.role == .login ? "welcomeLoginButton" : "welcomeSignupButton")
                .accessibilityHint(Text(viewModel.ctaAccessibilityHint))
            }
        }
        .frame(maxWidth: 540)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if let imageName = viewModel.content.backgroundImageName,
           UIImage(named: imageName) != nil {
            GeometryReader { proxy in
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        } else {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
        }
    }
}

#Preview("Welcome") {
    WelcomeView(viewModel: WelcomeViewModel())
}

#Preview("Large Dynamic Type") {
    WelcomeView(viewModel: WelcomeViewModel())
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
