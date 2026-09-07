import * as Location from 'expo-location';
import * as Haptics from 'expo-haptics';

// Calculate distance between two GPS coordinates in meters (Haversine formula)
export function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

// Map distance (0 to 100+ meters) to pulse interval speed (200ms to 2000ms)
export function calculatePulseInterval(distanceMeters) {
  if (distanceMeters <= 5) return 150;  // Very close: ultra fast pulses
  if (distanceMeters >= 100) return 2000; // Far away: slow 2-second pulses

  // Linear scaling between 5m and 100m
  const minInterval = 150;
  const maxInterval = 2000;
  const factor = (distanceMeters - 5) / (100 - 5);
  return Math.round(minInterval + factor * (maxInterval - minInterval));
}

// Trigger a single haptic feedback tick
export function triggerHapticFeedback(distanceMeters) {
  if (distanceMeters <= 15) {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
  } else if (distanceMeters <= 40) {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  } else {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }
}