import React from 'react';
import { StyleSheet, Text, View, FlatList, TouchableOpacity } from 'react-native';

const MOCK_FRIENDS = [
  { id: '1', name: 'Alex', lastMessage: 'Met at the coffee shop! ☕', time: '2m ago' },
  { id: '2', name: 'Jordan', lastMessage: 'That scavenger hunt was wild haha', time: '1h ago' },
  { id: '3', name: 'Taylor', lastMessage: 'Let us meet up again soon!', time: 'Yesterday' },
];

export default function ChatListScreen({ navigation }) {
  const renderItem = ({ item }) => (
    <TouchableOpacity style={styles.chatCard}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{item.name[0]}</Text>
      </View>
      <View style={styles.chatInfo}>
        <View style={styles.chatHeader}>
          <Text style={styles.name}>{item.name}</Text>
          <Text style={styles.time}>{item.time}</Text>
        </View>
        <Text style={styles.lastMessage} numberOfLines={1}>{item.lastMessage}</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Spazz Messages</Text>
        <TouchableOpacity 
          style={styles.huntButton}
          onPress={() => navigation.navigate('ScavengerHunt')}
        >
          <Text style={styles.huntButtonText}>⚡ Hunt</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={MOCK_FRIENDS}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        contentContainerStyle={styles.listContainer}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F0F14',
    paddingTop: 50,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#1A1A24',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#FFF',
  },
  huntButton: {
    backgroundColor: '#FF2A6D',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  huntButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
  },
  listContainer: {
    padding: 20,
  },
  chatCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#1A1A24',
    padding: 16,
    borderRadius: 12,
    marginBottom: 12,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#05D9E8',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  avatarText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#0F0F14',
  },
  chatInfo: {
    flex: 1,
  },
  chatHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  name: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: '600',
  },
  time: {
    color: '#666',
    fontSize: 12,
  },
  lastMessage: {
    color: '#AAA',
    fontSize: 14,
  },
});