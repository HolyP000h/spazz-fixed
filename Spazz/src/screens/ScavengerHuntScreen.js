import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, Text, View, TouchableOpacity, Animated, Alert } from 'react-native';
import * as Location from 'expo-location';
import { getDistanceMeters, calculatePulseInterval, triggerHapticFeedback } from '../services/ProximityEngine';

// Simulated Target Location (for testing without a 2nd device)
const MOCK_TARGET_LOCATION = {
  latitude: 37.78825,
  longitude: -122.4324,
};

export default function ScavengerHuntScreen({ navigation }) {
  const [distance, setDistance] = useState(null);
  const [pulseSpeed, setPulseSpeed] = useState(2000);
  const [isFound, setIsFound] = useState(false);
  const flashAnim = useRef(new Animated.Value(0.1)).current;

  useEffect(() => {
    let locationSubscription = null;

    (async () => {
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'Location access is required for Spazz proximity tracking.');
        return;
      }

      // Track location in real time
      locationSubscription = await Location.watchPositionAsync(
        {
          accuracy: Location.Accuracy.BestForNavigation,
          timeInterval: 1000,
          distanceInterval: 1,
        },
        (location) => {
          const currentLat = location.coords.latitude;
          const currentLon = location.coords.longitude;

          const dist = getDistanceMeters(
            currentLat,
            currentLon,
            MOCK_TARGET_LOCATION.latitude,
            MOCK_TARGET_LOCATION.longitude
          );

          setDistance(Math.round(dist));
          const newInterval = calculatePulseInterval(dist);
          setPulseSpeed(newInterval);

          if (dist <= 3) {
            setIsFound(true);
          }
        }
      );
    })();

    return () => {
      if (locationSubscription) locationSubscription.remove();
    };
  }, []);

  // Loop haptics and screen flashing based on proximity speed
  useEffect(() => {
    if (isFound) return;

    const interval = setInterval(() => {
      triggerHapticFeedback(distance || 100);

      Animated.sequence([
        Animated.timing(flashAnim, { toValue: 1, duration: pulseSpeed / 3, useNativeDriver: true }),
        Animated.timing(flashAnim, { toValue: 0.1, duration: (pulseSpeed / 3) * 2, useNativeDriver: true }),
      ]).start();
    }, pulseSpeed);

    return () => clearInterval(interval);
  }, [pulseSpeed, distance, isFound]);

  return (
    <View style={styles.container}>
      <Animated.View style={[styles.radarCircle, { opacity: flashAnim }]} />

      <Text style={styles.title}>SPAZZ RADAR</Text>
      
      <View style={styles.infoBox}>
        <Text style={styles.statusText}>
          {isFound ? "🎉 YOU FOUND THEM!" : "Scanning for nearby Spazz user..."}
        </Text>
        <Text style={styles.distanceText}>
          {distance !== null ? `${distance} meters away` : "Calibrating GPS..."}
        </Text>
      </View>

      {isFound && (
        <TouchableOpacity 
          style={styles.addFriendButton}
          onPress={() => {
            Alert.alert("Friend Added!", "You met a new connection.", [
              { text: "Open Chat", onPress: () => navigation.navigate("ChatList") }
            ]);
          }}
        >
          <Text style={styles.buttonText}>Add to Friend List</Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
        <Text style={styles.backButtonText}>Exit Radar</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F0F14',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  radarCircle: {
    position: 'absolute',
    width: 300,
    height: 300,
    borderRadius: 150,
    backgroundColor: '#FF2A6D',
  },
  title: {
    fontSize: 28,
    fontWeight: '900',
    color: '#05D9E8',
    letterSpacing: 2,
    marginBottom: 40,
  },
  infoBox: {
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.05)',
    padding: 24,
    borderRadius: 16,
    width: '90%',
    marginVertical: 20,
  },
  statusText: {
    color: '#FFF',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 10,
    textAlign: 'center',
  },
  distanceText: {
    color: '#FF2A6D',
    fontSize: 24,
    fontWeight: 'bold',
  },
  addFriendButton: {
    backgroundColor: '#05D9E8',
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderRadius: 30,
    marginTop: 20,
  },
  buttonText: {
    color: '#0F0F14',
    fontSize: 16,
    fontWeight: 'bold',
  },
  backButton: {
    marginTop: 30,
  },
  backButtonText: {
    color: '#888',
    fontSize: 14,
  }
});