#include <iostream>
#include <map>
#include <vector>

using namespace std;

// 当血量 > 140000/9 的时候，巨石碑需要8下才能杀怪

/*
	地狱塔0.128秒一次
	y1 =115*x(0<=x<1.25)
	y1 = 240*x(1.25<=x<5.25)
	y1 = 2400*x(x>=5.25)
	巨石碑1.5秒一次
	y2 =300+n*0.13(x>=0)
*/

vector<pair<int, double>> v1, v2;
map<int, int> m;
const int x = 15000;

int main()
{
	bool out = false, echars = false;

	int cnt1 = 0, cnt2 = 0, cnt3 = 0;
	for (int n = 0; n <= x; n++)
	{
		double res1 = 0, res2 = 0;

		double per_sec = 0.128, y = 0;
		// i是攻击的次数
		for (int i = 0; i <= 10000; i++)
		{
			double seconds = i * per_sec;
			if (seconds >= 0 && seconds < 1.25)
			{
				y += 115 * per_sec;
			}
			else if (seconds >= 1.25 && seconds < 5.25)
			{
				y += 240 * per_sec;
			}
			else
			{
				y += 2400 * per_sec;
			}
			if (out) printf("%d\t%.2lf\t%.2lf\n", i, seconds, y);
			if (y >= n)
			{
				res1 = seconds;
				break;
			}
		}

		if (out) cout << endl;

		per_sec = 1.5, y = 0;
		// i是攻击的次数
		for (int i = 0; i <= 100; i++)
		{
			double seconds = i * per_sec;
			y += 200 + n * 0.13;
			if (out) printf("%d\t%.2lf\t%.2lf\n", i, seconds, y);
			if (y >= n)
			{
				res2 = seconds;
				break;
			}
		}

		if (out) cout << endl;

		if (res1 < res2)
		{
			cnt1++;
			v1.push_back({ n, res1 });
			m.insert({ n, 1 });
			if (out) printf("地狱塔 win 血量 %d\n", n);
		}
		else if (res1 > res2)
		{
			cnt2++;
			v2.push_back({ n, res2 });
			m.insert({ n, 2 });
			if (out) printf("巨石碑 win 血量 %d\n", n);
		}
		else if (res1 == res2)
		{
			cnt3++;
			m.insert({ n, 0 });
			if (out) printf("win win 血量 %d\n", n);
		}

		if (out) cout << endl << endl << endl;
	}

	printf("地狱塔\t%d\n", cnt1);
	printf("巨石碑\t%d\n", cnt2);
	printf("打平\t%d\n", cnt3);

	if (echars)
	{
		cout << endl;
		cout << '[';
		for (int n = 0; n <= x; n++)
		{
			if (n != x)
				cout << n << ",";
			else
				cout << n;
		}
		cout << "]";

		cout << endl;
		cout << '[';
		for (int n = 0; n <= x; n++)
		{
			if (n != x)
				cout << m[n] << ",";
			else
				cout << m[n];
		}
		cout << "]";
	}

	return 0;
}