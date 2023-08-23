#include "stdafx.h"
#include "test.h"
#include "common/log.h"

#define		COLOR_TRANSPARENT		0x00000000 // 透明色

CPointScanner CPointScanner::g_test;

CPointScanner::CPointScanner()
	: m_ptStart(-1, -1)
	, m_screenWidth(GetSystemMetrics(SM_CXSCREEN))
	, m_screenHeight(GetSystemMetrics(SM_CYSCREEN))
	, m_colorDE76(0)
	, m_destColor(COLOR_TRANSPARENT)
{

}

CPointScanner::~CPointScanner()
{
	ReleaseData();
}

vector<D2UI::CSkPoint> CPointScanner::ScanPoints()
{
	vector<D2UI::CSkPoint> list;
	if (m_ptStart.x < 0 || m_ptStart.y < 0 || !m_pRT) return list;

	InitData();
	list = DoScan();
	ReleaseData();

	return list;
}

/**
 * 初始化数据
 */
void CPointScanner::InitData()
{
	if (m_screenWidth <= 0 || m_screenHeight <= 0)
		return;

	m_pixels = new bool* [m_screenWidth];
	for (int i = 0; i < m_screenWidth; i++)
	{
		m_pixels[i] = new bool[m_screenHeight];
		ZeroMemory(m_pixels[i], m_screenHeight * sizeof(bool));
	}
}

/**
 * 释放数据
 */
void CPointScanner::ReleaseData()
{
	if (m_pixels == NULL)
		return;

	for (int i = 0; i < m_screenHeight; i++)
		delete[] m_pixels[i];
	delete[] m_pixels;

	m_pixels = NULL;
}

DWORD CPointScanner::GetPixel(int x, int y)
{
	if (m_pRT)
		return m_pRT->GetPixel(x, y);
	return COLOR_TRANSPARENT;
}

DWORD CPointScanner::GetPixel(D2UI::CSkPoint pt)
{
	return GetPixel(pt.x, pt.y);
}

vector<D2UI::CSkPoint> CPointScanner::DoScan()
{
	vector <D2UI::CSkPoint> lst;
	if (m_pixels == NULL) return lst;

	// 拿到所需要的目标颜色
	m_destColor = GetPixel(m_ptStart);
	if (m_destColor == COLOR_TRANSPARENT) return lst;

	// 初始化栈
	std::stack<D2UI::CSkPoint> stk;
	stk.push(m_ptStart);
	// 扫描线为y
	while (!stk.empty())
	{
		auto& front = stk.top();
		stk.pop();
		int now_x = front.x, now_y = front.y; // 当前扫描的点 x和y坐标
		m_pixels[now_x][now_y] = TRUE; // 标记当前点已经扫描过

		// 沿着扫描线向左扫
		int xLeft = ScanHorizontalLine(now_x, 0, now_y, -1); // 左边界
		// 沿着扫描线向右扫
		int xRight = ScanHorizontalLine(now_x, m_screenWidth - 1, now_y, 1); // 右边界

		// 扫描上下两条线
		ScanVerticalLine(stk, xLeft, xRight, now_y + (-1), -1);
		ScanVerticalLine(stk, xLeft, xRight, now_y + (1), 1);
	}

	for (int i = 0; i < m_screenWidth; i++)
		for (int j = 0; j < m_screenHeight; j++)
			if (m_pixels[i][j]) lst.push_back(D2UI::CSkPoint(i, j));

	return lst;
}

/**
 * @remark:		扫描的 起点 终点 为闭区间 [start, end]
 * @plist:		存放所需点
 * @start:		扫描开始的起点
 * @end:		扫描开始的终点
 * @line:		扫描线的y坐标
 * @dirc:		扫描的方向【-1表示向左边，1表示向右】
 */
int CPointScanner::ScanHorizontalLine(int start, int end, int y, INT8 dirc)
{
	// 判断是否到达终点
#define NotReachEnd(direction, now_postion, end) \
    (direction) < (0) ? (now_postion) >= (end) : (now_postion) <= (end)

	// 边界的极端情况就是终点，因为再往外面就越界了
	int endPoint = end;

	for (int i = start + dirc; NotReachEnd(dirc, i, end); i += dirc)
	{
		if (IsReqPoint(i, y))
		{
			m_pixels[i][y] = TRUE;
		}
		else
		{
			// 减去dirc是往相反的方向走一个点，因为寻找的左右终点是图形内部内部的点，而不是边界点
			endPoint = i - dirc;
			break;
		}
	}

	return endPoint;
}

/**
 * @remark:		沿着dirc方向上下扫描，寻找新的扫描点压入stk，区间[xLeft, xRight]
 * @plist:		存放所需点
 * @xLeft:		扫描开始的起点
 * @xRight:		扫描开始的终点
 * @y:			扫描线的y坐标
 * @dirc:		扫描的方向【-1表示向上，1表示向下】
 */
void CPointScanner::ScanVerticalLine(stack<D2UI::CSkPoint>& stk, int xLeft, int xRight, int y, INT8 dirc)
{
	// 在上一处的区间内 搜索
	for (int i = xLeft; i <= xRight; i++)
	{
		if (IsReqPoint(i, y))
		{
			int rBound = i + 1; // rigth boundary
			// 找到最右边的边界 入栈
			while (IsReqPoint(rBound, y))
				rBound++;

			i = --rBound;
			stk.push(D2UI::CSkPoint(rBound, y));
		}
	}
}

/**
 * @remark: 是否是所需要的点 Is it a required point
 * @return: 如果此点是需要收集的则返回true
 */
bool CPointScanner::IsReqPoint(int x, int y)
{
	if (!InBound(x, y)) return FALSE;
	DWORD nowPosColor = GetPixel(x, y);
	double de76 = CalculateDE76(nowPosColor, m_destColor);
	return de76 <= m_colorDE76 && !m_pixels[x][y];
}

/**
 * @remark: 判断是否在边界内
 */
bool CPointScanner::InBound(int x, int y)
{
	return (x >= 0 && x < m_screenWidth && y >= 0 && y < m_screenHeight);
}

/**
 * @remark: 使用DE76公式计算颜色差值
 * @color1: BGR格式
 * @color2: BGR格式
 */
double CPointScanner::CalculateDE76(DWORD color1, DWORD color2)
{
	BYTE r1 = GetRValue(color1);
	BYTE g1 = GetGValue(color1);
	BYTE b1 = GetBValue(color1);

	BYTE r2 = GetRValue(color2);
	BYTE g2 = GetGValue(color2);
	BYTE b2 = GetBValue(color2);

	double deltaL = 0.299 * (r2 - r1) + 0.587 * (g2 - g1) + 0.114 * (b2 - b1);
	double deltaA = r2 - r1 - deltaL;
	double deltaB = b2 - b1 - deltaL;

	return sqrt(deltaA * deltaA + deltaB * deltaB + deltaL * deltaL);
}