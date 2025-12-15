import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    redirect: '/login'
  },
  // 学生路由
  {
    path: '/student',
    name: 'StudentLayout',
    component: () => import('@/views/student/Layout.vue'),
    meta: { requiresAuth: true, role: '学生' },
    children: [
      {
        path: 'dashboard',
        name: 'StudentDashboard',
        component: () => import('@/views/student/Dashboard.vue'),
        meta: { title: '首页' }
      },
      {
        path: 'courses',
        name: 'CourseSelection',
        component: () => import('@/views/student/CourseSelection.vue'),
        meta: { title: '选课中心' }
      },
      {
        path: 'schedule',
        name: 'StudentSchedule',
        component: () => import('@/views/student/MySchedule.vue'),
        meta: { title: '我的课表' }
      },
      {
        path: 'change-password',
        name: 'StudentChangePassword',
        component: () => import('@/views/student/ChangePassword.vue'),
        meta: { title: '修改密码' }
      }
    ]
  },
  // 教师路由
  {
    path: '/teacher',
    name: 'TeacherLayout',
    component: () => import('@/views/teacher/Layout.vue'),
    meta: { requiresAuth: true, role: '教师' },
    children: [
      {
        path: 'dashboard',
        name: 'TeacherDashboard',
        component: () => import('@/views/teacher/Dashboard.vue'),
        meta: { title: '首页' }
      },
      {
        path: 'schedule',
        name: 'TeacherSchedule',
        component: () => import('@/views/teacher/MySchedule.vue'),
        meta: { title: '我的课表' }
      },
      {
        path: 'students/:instanceId',
        name: 'StudentList',
        component: () => import('@/views/teacher/StudentList.vue'),
        meta: { title: '学生名单' }
      },
      {
        path: 'change-password',
        name: 'TeacherChangePassword',
        component: () => import('@/views/teacher/ChangePassword.vue'),
        meta: { title: '修改密码' }
      }
    ]
  },
  // 教务路由
  {
    path: '/admin',
    name: 'AdminLayout',
    component: () => import('@/views/admin/Layout.vue'),
    meta: { requiresAuth: true, role: '教务' },
    children: [
      {
        path: 'dashboard',
        name: 'AdminDashboard',
        component: () => import('@/views/admin/Dashboard.vue'),
        meta: { title: '系统概览' }
      },
      {
        path: 'statistics',
        name: 'Statistics',
        component: () => import('@/views/admin/Statistics.vue'),
        meta: { title: '选课统计' }
      },
      {
        path: 'users',
        name: 'UserManagement',
        component: () => import('@/views/admin/UserManagement.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: 'courses',
        name: 'CourseManagement',
        component: () => import('@/views/admin/CourseManagement.vue'),
        meta: { title: '课程管理' }
      },
      {
        path: 'instances',
        name: 'InstanceManagement',
        component: () => import('@/views/admin/InstanceManagement.vue'),
        meta: { title: '开课管理' }
      },
      {
        path: 'change-password',
        name: 'AdminChangePassword',
        component: () => import('@/views/admin/ChangePassword.vue'),
        meta: { title: '修改密码' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  // 需要登录的路由
  if (to.meta.requiresAuth) {
    if (!authStore.isLoggedIn) {
      next('/login')
      return
    }

    // 角色验证
    if (to.meta.role && authStore.userRole !== to.meta.role) {
      // 重定向到对应角色的首页
      const roleRoutes = {
        '学生': '/student/dashboard',
        '教师': '/teacher/dashboard',
        '教务': '/admin/dashboard'
      }
      next(roleRoutes[authStore.userRole] || '/login')
      return
    }
  }

  next()
})

export default router
