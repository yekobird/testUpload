package cn.com.essence.testttt.strategy;

import cn.com.essence.testttt.User;
import cn.com.essence.testttt.User1;
import cn.hutool.core.util.RandomUtil;
import com.google.common.collect.Lists;
import org.springframework.beans.BeanUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * @author ：hxd
 * @description：
 * @date ：Created in 2020-11-12 9:32
 */
public class Random {
    public static void main(String[] args) {
       List list = getRandomNum2(1,9,9);
        System.out.println(list);
    }


    public static List<Integer> getRandomNum2(int min, int max, int targetLength) {
        if(max-min < 1){
            System.out.print("最小值和最大值数据有误");
            return null;
        }else if(max+1-min <targetLength){
            System.out.print("指定随机个数超过范围");
            return null;
        }
        List<Integer> list = new ArrayList<>();
        List<Integer> reqList = new ArrayList<>();
        for (int i = min; i <= max; i++) {
            reqList.add(i);
        }
        for (int i = 0; i < targetLength; i++) {
            // 取出一个随机角标.
            int r = (int) (Math.random() * reqList.size());
            list.add(reqList.get(r));
            // 移除已经取过的值.
            reqList.remove(r);
        }
        return list;
    }

}
