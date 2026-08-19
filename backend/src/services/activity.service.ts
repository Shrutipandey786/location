import { prisma } from '../config/database.js';
import { AuthenticatedUser } from '../middleware/auth.middleware.js';

export class ActivityService {
  public static async getActivities(currentUser: AuthenticatedUser, type?: string) {
    let activities;

    if (type && type.trim().length > 0) {
      const normalized = this.normalizeType(type);
      activities = await prisma.activity.findMany({
        where: { userId: currentUser.id, type: normalized },
        orderBy: { createdAt: 'desc' },
      });
    } else {
      activities = await prisma.activity.findMany({
        where: { userId: currentUser.id },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (activities.length === 0 && (!type || type.trim().length === 0)) {
      activities = await this.seedInitialActivities(currentUser);
    }

    const latestLoc = await prisma.location.findFirst({
      where: { userId: currentUser.id },
      orderBy: { updatedAt: 'desc' },
    });

    const latestDevice = await prisma.deviceStatus.findUnique({
      where: { userId: currentUser.id },
    });

    const currentLat = latestLoc ? latestLoc.latitude : 28.6139;
    const currentLng = latestLoc ? latestLoc.longitude : 77.2090;
    const currentAddress = latestLoc?.address || `${currentLat.toFixed(4)}, ${currentLng.toFixed(4)}`;
    const batteryLevel = latestDevice ? latestDevice.batteryLevel : 95;

    return activities.map((act) => {
      const lat = act.latitude !== null && act.latitude !== undefined ? act.latitude : currentLat;
      const lng = act.longitude !== null && act.longitude !== undefined ? act.longitude : currentLng;
      const createdAt = act.createdAt ? act.createdAt.toISOString().slice(0, 19) : new Date().toISOString().slice(0, 19);

      return {
        id: Number(act.id),
        title: act.title || 'Telemetry Log',
        details: act.details || 'Activity registered.',
        type: act.type || 'GPS_SYNC',
        latitude: lat,
        longitude: lng,
        address: currentAddress,
        userName: currentUser.name || 'System Node',
        deviceModel: 'Android',
        batteryLevel,
        createdAt,
      };
    });
  }

  private static async seedInitialActivities(currentUser: AuthenticatedUser) {
    const now = new Date();

    const seeds = [
      {
        userId: currentUser.id,
        title: 'GPS Telemetry Synced',
        details: 'Real-time GPS coordinates synchronized with central server.',
        type: 'GPS_SYNC',
        latitude: 28.6139,
        longitude: 77.2090,
        createdAt: new Date(now.getTime() - 5 * 60 * 1000),
      },
      {
        userId: currentUser.id,
        title: 'PTT Voice Intercom Call',
        details: 'Push-to-Talk voice channel session established (0:14s duration).',
        type: 'PTT_VOICE',
        latitude: 28.6145,
        longitude: 77.2095,
        createdAt: new Date(now.getTime() - 25 * 60 * 1000),
      },
      {
        userId: currentUser.id,
        title: 'Camera Telemetry HUD Snapshot',
        details: 'Live camera optical snapshot captured and location tagged.',
        type: 'CAMERA_TELEMETRY',
        latitude: 28.6150,
        longitude: 77.2100,
        createdAt: new Date(now.getTime() - (70 * 60 * 1000)),
      },
      {
        userId: currentUser.id,
        title: 'Geofence Security Perimeter Check',
        details: 'Entered designated safe zone boundary at Checkpoint Alpha.',
        type: 'GEOFENCE',
        latitude: 28.6155,
        longitude: 77.2105,
        createdAt: new Date(now.getTime() - (120 * 60 * 1000)),
      },
    ];

    for (const seed of seeds) {
      await prisma.activity.create({ data: seed });
    }

    return prisma.activity.findMany({
      where: { userId: currentUser.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  private static normalizeType(inputType: string): string {
    const upper = inputType.trim().toUpperCase();
    if (upper === 'LOCATION' || upper === 'LOCATION_UPDATE') return 'GPS_SYNC';
    if (upper === 'PTT' || upper === 'PTT_CALL') return 'PTT_VOICE';
    if (upper === 'SOS_ALERT') return 'SOS';
    if (upper === 'SNAPSHOT' || upper === 'CAMERA_SNAPSHOT') return 'CAMERA_TELEMETRY';
    if (upper === 'GEOFENCE_ALERT') return 'GEOFENCE';
    return upper;
  }
}
