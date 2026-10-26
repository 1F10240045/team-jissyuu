import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// 1. 動作確認用 API
export const helloWorld = functions.https.onRequest((req, res) => {
  res.status(200).send("LINE Mini App Backend API is running!");
});

// 2. Firestore テスト保存 API（new Date() に変更）
export const createSampleData = functions.https.onRequest(async (req, res) => {
  try {
    const docRef = db.collection("users").doc("test_user_01");
    await docRef.set({
      displayName: "テストユーザー",
      createdAt: new Date(),
    });
    res.status(200).send({ success: true, message: "User created in Firestore!" });
  } catch (error) {
    res.status(500).send({ success: false, error: (error as Error).message });
  }
});