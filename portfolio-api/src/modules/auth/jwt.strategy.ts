import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import * as jwksRsa from 'jwks-rsa';
import { PrismaService } from '../../prisma.service';

interface JwtPayload {
  sub: string;
  email: string;
  aud: string;
  role: string;
  iat: number;
  exp: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    const supabaseUrl = configService.get<string>('supabase.url');

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKeyProvider: jwksRsa.passportJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `${supabaseUrl}/auth/v1/.well-known/jwks.json`,
      }),
      algorithms: ['RS256'],
      audience: 'authenticated',
      issuer: `${supabaseUrl}/auth/v1`,
    });
  }

  async validate(payload: JwtPayload) {
    const { sub: supabaseId, email } = payload;

    if (!supabaseId || !email) {
      throw new UnauthorizedException('Invalid token payload');
    }

    // Find or create user in our database
    let user = await this.prisma.user.findUnique({
      where: { supabaseId },
      include: { subscription: true },
    });

    if (!user) {
      // Create user on first authentication
      user = await this.prisma.user.create({
        data: {
          supabaseId,
          email,
        },
        include: { subscription: true },
      });
    }

    return user;
  }
}
