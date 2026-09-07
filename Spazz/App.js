import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import ChatListScreen from './src/screens/ChatListScreen';
import ScavengerHuntScreen from './src/screens/ScavengerHuntScreen';

const Stack = createNativeStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="ChatList" component={ChatListScreen} />
        <Stack.Screen name="ScavengerHunt" component={ScavengerHuntScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}