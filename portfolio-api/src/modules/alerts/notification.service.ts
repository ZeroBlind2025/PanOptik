import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);
  private initialized = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const privateKey = this.configService.get<string>('firebase.privateKey');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');

    if (projectId && privateKey && clientEmail) {
      try {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey,
            clientEmail,
          }),
        });
        this.initialized = true;
        this.logger.log('Firebase Admin initialized');
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin', error.message);
      }
    } else {
      this.logger.warn('Firebase credentials not configured');
    }
  }

  async sendPushNotification(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<boolean> {
    if (!this.initialized) {
      this.logger.warn('Firebase not initialized, skipping notification');
      return false;
    }

    if (!fcmToken) {
      this.logger.warn('No FCM token provided');
      return false;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data,
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'portfolio_alerts',
          },
        },
      });

      this.logger.log(`Notification sent successfully to ${fcmToken.slice(0, 20)}...`);
      return true;
    } catch (error) {
      this.logger.error('Failed to send notification', error.message);
      return false;
    }
  }
}
