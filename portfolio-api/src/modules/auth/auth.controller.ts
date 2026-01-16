import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  async getMe(@CurrentUser() user: any) {
    return this.authService.getMe(user.id);
  }
}

@Controller('users')
export class UsersController {
  constructor(private authService: AuthService) {}

  @Post('fcm-token')
  @UseGuards(AuthGuard('jwt'))
  async updateFcmToken(
    @CurrentUser() user: any,
    @Body('token') token: string,
  ) {
    return this.authService.updateFcmToken(user.id, token);
  }
}
