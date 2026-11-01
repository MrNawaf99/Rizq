const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// تحديد خصائص الخادم
setGlobalOptions({ maxInstances: 10 });

// ==========================================
// 1) PUSH NOTIFICATION BRIDGE
// ==========================================
exports.sendNotification = onDocumentCreated(
  "users/{userId}/notifications/{id}",
  async (event) => {
    const data = event.data.data();
    const userId = event.params.userId;

    // معالجة المتغيرات (مثال: دمج رقم الشهر مع الرسالة)
    let bodyText = data.message || "New notification";
    if (data.args && Object.keys(data.args).length > 0) {
      const argsString = Object.values(data.args).join(" ");
      bodyText = `${bodyText} ${argsString}`;
    }

    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();
    const token = userData ? userData.fcmToken : null;

    if (!token) return null;

    const payload = {
      token: token,
      notification: {
        title: "Jam3iya",
        body: bodyText,
      },
      data: {
        type: data.type || "general",
        groupId: String(data.groupId || ""),
        click_action: "FLUTTER_NOTIFICATION_CLICK" // ضروري جداً لـ Flutter
      },
    };

    try {
      await admin.messaging().send(payload);
      console.log("Notification sent successfully to:", userId);
    } catch (error) {
      console.error("Error sending notification:", error);
      // 🔥 Token Validation & Cleanup
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-argument"
      ) {
        await admin.firestore().collection("users").doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        console.log("Dead token removed for user:", userId);
      }
    }
    return null;
  }
);

// ==========================================
// 2) MONTHLY REMINDER ENGINE
// ==========================================
exports.monthlyReminderEngine = onSchedule("0 * * * *", async (event) => {
  const db = admin.firestore();
  
  const now = new Date();
  const currentMonthKey = `${now.getUTCFullYear()}-${now.getUTCMonth() + 1}`; 
  const currentUtcHour = now.getUTCHours();

  const groupsSnapshot = await db.collection("groups")
    .where("isCompleted", "==", false)
    .where("isClosed", "==", false)
    .where("distributionStarted", "==", true)
    .get();

  let batch = db.batch();
  let operations = 0;

  for (const doc of groupsSnapshot.docs) {
    const group = doc.data();

    // منع التكرار
    if (group.lastReminderSentMonth === currentMonthKey) continue;

    // فحص وقت الإشعار مقارنة بسيرفر UTC
    const targetHour = group.notificationHour || 9;
    if (currentUtcHour !== targetHour) continue;

    const payments = group.payments || {};
    const paidList = payments[currentMonthKey] || [];
    const members = group.members || [];
    const unpaidMembers = members.filter(m => !paidList.includes(m));

    if (unpaidMembers.length === 0) {
      batch.update(doc.ref, { lastReminderSentMonth: currentMonthKey });
      operations++;
      continue;
    }

    const messageText = (group.monthlyMessage && group.monthlyMessage.trim() !== "") 
                        ? group.monthlyMessage 
                        : "payment_reminder";

    for (const uid of unpaidMembers) {
      const notifRef = db.collection("users").doc(uid).collection("notifications").doc();
      batch.set(notifRef, {
        message: messageText,
        args: { month: currentMonthKey },
        type: "monthly_reminder",
        groupId: doc.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false
      });
      operations++;
    }

    batch.update(doc.ref, { lastReminderSentMonth: currentMonthKey });
    operations++;

    if (operations >= 400) {
      await batch.commit();
      batch = db.batch(); // ⭐ STRICT FIX: تهيئة الـ Batch من جديد
      operations = 0;
    }
  }

  if (operations > 0) {
    await batch.commit();
  }

  console.log("Monthly Reminder Engine Completed for:", currentMonthKey);
  return null;
});