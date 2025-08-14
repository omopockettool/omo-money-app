import SwiftUI

/// Animation helper for consistent and smooth animations throughout OMOMoney app
/// Provides predefined animation curves and durations for better UX
struct AnimationHelper {
    
    // MARK: - Animation Curves
    
    /// Smooth spring animation for UI transitions
    static let smoothSpring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)
    
    /// Quick spring animation for immediate feedback
    static let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
    
    /// Gentle ease animation for subtle changes
    static let gentleEase = Animation.easeInOut(duration: 0.4)
    
    /// Smooth ease animation for smooth transitions
    static let smoothEase = Animation.easeInOut(duration: 0.6)
    
    /// Quick ease animation for fast feedback
    static let quickEase = Animation.easeInOut(duration: 0.2)
    
    // MARK: - Loading Animations
    
    /// Pulse animation for loading states
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    
    /// Bounce animation for success states
    static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0.2)
    
    /// Fade animation for smooth transitions
    static let fade = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Navigation Animations
    
    /// Slide animation for navigation transitions
    static let slide = Animation.easeInOut(duration: 0.4)
    
    /// Scale animation for modal presentations
    static let scale = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)
    
    // MARK: - List Animations
    
    /// List item appearance animation
    static let listItem = Animation.easeInOut(duration: 0.3).delay(0.1)
    
    /// List item removal animation
    static let listItemRemoval = Animation.easeInOut(duration: 0.2)
    
    // MARK: - Form Animations
    
    /// Form field focus animation
    static let formFocus = Animation.easeInOut(duration: 0.2)
    
    /// Form validation animation
    static let formValidation = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)
    
    // MARK: - Button Animations
    
    /// Button press animation
    static let buttonPress = Animation.easeInOut(duration: 0.1)
    
    /// Button state change animation
    static let buttonState = Animation.easeInOut(duration: 0.2)
    
    // MARK: - Error Animations
    
    /// Error shake animation
    static let errorShake = Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    
    /// Error fade animation
    static let errorFade = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Success Animations
    
    /// Success checkmark animation
    static let successCheck = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)
    
    /// Success celebration animation
    static let successCelebration = Animation.easeInOut(duration: 0.5)
}

// MARK: - Animation Extensions

extension View {
    
    /// Apply smooth spring animation
    func smoothSpringAnimation() -> some View {
        self.animation(AnimationHelper.smoothSpring, value: UUID())
    }
    
    /// Apply quick spring animation
    func quickSpringAnimation() -> some View {
        self.animation(AnimationHelper.quickSpring, value: UUID())
    }
    
    /// Apply gentle ease animation
    func gentleEaseAnimation() -> some View {
        self.animation(AnimationHelper.gentleEase, value: UUID())
    }
    
    /// Apply smooth ease animation
    func smoothEaseAnimation() -> some View {
        self.animation(AnimationHelper.smoothEase, value: UUID())
    }
    
    /// Apply quick ease animation
    func quickEaseAnimation() -> some View {
        self.animation(AnimationHelper.quickEase, value: UUID())
    }
    
    /// Apply pulse animation
    func pulseAnimation() -> some View {
        self.animation(AnimationHelper.pulse, value: UUID())
    }
    
    /// Apply bounce animation
    func bounceAnimation() -> some View {
        self.animation(AnimationHelper.bounce, value: UUID())
    }
    
    /// Apply fade animation
    func fadeAnimation() -> some View {
        self.animation(AnimationHelper.fade, value: UUID())
    }
    
    /// Apply slide animation
    func slideAnimation() -> some View {
        self.animation(AnimationHelper.slide, value: UUID())
    }
    
    /// Apply scale animation
    func scaleAnimation() -> some View {
        self.animation(AnimationHelper.scale, value: UUID())
    }
    
    /// Apply list item animation
    func listItemAnimation() -> some View {
        self.animation(AnimationHelper.listItem, value: UUID())
    }
    
    /// Apply form focus animation
    func formFocusAnimation() -> some View {
        self.animation(AnimationHelper.formFocus, value: UUID())
    }
    
    /// Apply button press animation
    func buttonPressAnimation() -> some View {
        self.animation(AnimationHelper.buttonPress, value: UUID())
    }
    
    /// Apply error shake animation
    func errorShakeAnimation() -> some View {
        self.animation(AnimationHelper.errorShake, value: UUID())
    }
    
    /// Apply success check animation
    func successCheckAnimation() -> some View {
        self.animation(AnimationHelper.successCheck, value: UUID())
    }
}
