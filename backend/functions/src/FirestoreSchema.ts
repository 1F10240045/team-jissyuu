import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore のコレクション名定義
 */
export const FIRESTORE_COLLECTIONS = {
  users: "users",
  teams: "teams",
  posts: "posts",
  comments: "comments",
  walkLogs: "walkLogs",
} as const;

export type FirestoreCollectionName =
  (typeof FIRESTORE_COLLECTIONS)[keyof typeof FIRESTORE_COLLECTIONS];

export type FirestoreTimestamp = Timestamp;

export type AgeGroup = "50代" | "60代" | "70代" | "80代" | "90代+";

// ユーザープロフィール
export interface UserProfile {
  userId: string;
  displayName: string;
  avatarUrl: string;
  district: string;     // 区名や地域名
  ageGroup: AgeGroup;
  teamId: string | null;
  totalSteps: number;
  totalDistanceKm: number;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

// チーム情報
export interface Team {
  teamId: string;
  name: string;
  district: string;
  description: string;
  managerUserId: string;
  memberCount: number;
  totalSteps: number;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

// 投稿データ
export interface Post {
  postId: string;
  userId: string;
  authorName: string;
  district: string;
  content: string;
  imageUrls: string[];
  likesCount: number;
  commentsCount: number;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

// コメント
export interface Comment {
  commentId: string;
  postId: string;
  userId: string;
  authorName: string;
  content: string;
  createdAt: FirestoreTimestamp;
}

// 歩行ログ
export interface WalkLog {
  walkLogId: string;
  userId: string;
  teamId: string | null;
  date: string; // YYYY-MM-DD
  steps: number;
  distanceKm: number;
  createdAt: FirestoreTimestamp;
}

export interface FirestoreSchema {
  users: UserProfile;
  teams: Team;
  posts: Post;
  comments: Comment;
  walkLogs: WalkLog;
}